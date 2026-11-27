"""Tests for the CircleCI builder's tmpfs workspace."""

import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest


SETUP_SCRIPT = Path(__file__).with_name("setup_workspace.sh")
ARM_RELEASE_SCRIPT = Path(__file__).resolve().parent.parent / "release_qemu_arm64.sh"

WORKSPACE_COMMAND = """#!/usr/bin/env python3
import json
import os
from pathlib import Path
import sys

name = Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ["CALL_LOG"], "a") as log:
    log.write(json.dumps([name, *args]) + "\\n")

state = Path(os.environ["MOUNT_STATE"])
if name == "mountpoint":
    sys.exit(0 if state.exists() else 1)
if name == "findmnt":
    if args[-1] == os.environ.get("NON_TMPFS_PATH"):
        sys.exit(1)
    sys.exit(0 if state.exists() and state.read_text() == "tmpfs" else 1)
if name == "mount":
    if os.environ.get("FAIL_MOUNT"):
        sys.exit(1)
    state.write_text("tmpfs")
elif name == "git" and args[0] == "clone":
    if os.environ.get("FAIL_CLONE"):
        sys.exit(1)
    destination = Path(args[-1])
    if destination.exists() and any(destination.iterdir()):
        sys.exit(1)
    (destination / ".git").mkdir(parents=True)
"""


class WorkspaceTests(unittest.TestCase):

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.workspace = self.root / "workspace"
        self.state = self.root / "mount-state"
        self.log = self.root / "commands.jsonl"
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for name in ("mountpoint", "findmnt", "mount", "git"):
            command = self.bin / name
            command.write_text(WORKSPACE_COMMAND)
            command.chmod(0o755)
        self.environment = os.environ.copy()
        self.environment.update({
            "PATH": str(self.bin) + os.pathsep + os.environ["PATH"],
            "MOUNT_STATE": str(self.state),
            "CALL_LOG": str(self.log),
        })

    def run_setup(self):
        return subprocess.run(
            ["bash", str(SETUP_SCRIPT), str(self.workspace), "revision"],
            env=self.environment, capture_output=True, text=True, timeout=10,
        )

    def commands(self, name):
        if not self.log.exists():
            return []
        return [command for line in self.log.read_text().splitlines()
                if (command := json.loads(line))[0] == name]

    def test_mounts_tmpfs_clones_and_prepares_directories(self):
        result = self.run_setup()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.commands("mount"), [[
            "mount", "-t", "tmpfs", "-o", "size=75%,mode=0755",
            "tmpfs", str(self.workspace),
        ]])
        self.assertEqual(self.commands("git"), [
            ["git", "clone", "https://github.com/GNS3/gns3-vm.git",
             str(self.workspace / "gns3-vm")],
            ["git", "-C", str(self.workspace / "gns3-vm"), "checkout", "revision"],
        ])
        self.assertTrue((self.workspace / "virtualbox").is_dir())
        self.assertEqual(stat.S_IMODE((self.workspace / "tmp").stat().st_mode), 0o700)

    def test_reuses_existing_tmpfs_and_clone(self):
        for _ in range(2):
            result = self.run_setup()
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.commands("mount")), 1)
        self.assertEqual(len([command for command in self.commands("git")
                              if command[1] == "clone"]), 1)
        self.assertEqual(len([command for command in self.commands("git")
                              if "checkout" in command]), 2)

    def test_refuses_to_hide_existing_files(self):
        self.workspace.mkdir()
        existing = self.workspace / "existing"
        existing.write_text("keep")
        result = self.run_setup()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("non-empty workspace", result.stderr)
        self.assertEqual(existing.read_text(), "keep")
        self.assertEqual(self.commands("mount"), [])
        self.assertEqual(self.commands("git"), [])

    def test_refuses_a_non_tmpfs_mount(self):
        self.workspace.mkdir()
        self.state.write_text("ext4")
        result = self.run_setup()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("not mounted as tmpfs", result.stderr)
        self.assertEqual(self.commands("mount"), [])
        self.assertEqual(self.commands("git"), [])

    def test_refuses_a_non_tmpfs_directory_inside_the_mount(self):
        self.environment["NON_TMPFS_PATH"] = str(self.workspace / "virtualbox")
        result = self.run_setup()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Build directory is not on tmpfs", result.stderr)
        self.assertEqual(self.commands("git"), [])

    def test_refuses_workspace_symlinks(self):
        self.workspace.symlink_to(self.root, target_is_directory=True)
        result = self.run_setup()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("non-symlink directory", result.stderr)
        self.assertEqual(self.commands("mount"), [])

    def test_refuses_symlinks_inside_the_mount(self):
        self.workspace.mkdir()
        self.state.write_text("tmpfs")
        (self.workspace / "tmp").symlink_to(self.root, target_is_directory=True)
        result = self.run_setup()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("symlink in the build workspace", result.stderr)
        self.assertEqual(self.commands("git"), [])

    def test_mount_failure_does_not_clone_to_disk(self):
        self.environment["FAIL_MOUNT"] = "1"
        result = self.run_setup()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.commands("git"), [])
        self.assertFalse((self.workspace / "gns3-vm").exists())

    def test_clone_failure_does_not_continue_to_checkout(self):
        self.environment["FAIL_CLONE"] = "1"
        result = self.run_setup()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(self.commands("git")), 1)
        self.assertEqual(self.commands("git")[0][1], "clone")


class ArmReleaseTemporaryDirectoryTests(unittest.TestCase):

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for name, script in {
            "cp": '#!/bin/sh\nprintf "%s\\n" "$@" > "$COPY_LOG"\n',
            "curl": '#!/bin/sh\nprintf archive\n',
            "7z": '#!/bin/sh\nprintf "%s\\n" "$3" > "$EXTRACT_LOG"\nexit 41\n',
        }.items():
            command = self.bin / name
            command.write_text(script)
            command.chmod(0o755)
        self.tmpdir = self.root / "temporary files"
        self.tmpdir.mkdir()
        self.environment = os.environ.copy()
        self.environment.update({
            "PATH": str(self.bin) + os.pathsep + os.environ["PATH"],
            "TMPDIR": str(self.tmpdir),
            "GNS3VM_VERSION": "1.2.3",
            "COPY_LOG": str(self.root / "copy.log"),
            "EXTRACT_LOG": str(self.root / "extract.log"),
        })

    def run_release(self, *args):
        result = subprocess.run(
            ["bash", str(ARM_RELEASE_SCRIPT), "v3.1.0", *args],
            cwd=self.root, env=self.environment, capture_output=True, text=True,
            timeout=10,
        )
        self.assertEqual(result.returncode, 41, result.stderr)
        return (self.root / "extract.log").read_text().strip()

    def test_supplied_archive_uses_tmpdir(self):
        archive = str(self.tmpdir / "GNS3VM.Base.ARM64.1.2.3.zip")
        self.assertEqual(self.run_release("source file.zip"), archive)
        self.assertEqual((self.root / "copy.log").read_text().splitlines(),
                         ["source file.zip", archive])

    def test_downloaded_archive_uses_tmpdir(self):
        archive = self.tmpdir / "GNS3VM.Base.ARM64.0.24.0.zip"
        self.assertEqual(self.run_release(), str(archive))
        self.assertEqual(archive.read_text(), "archive")

    def test_archive_already_in_tmpdir_is_not_copied_onto_itself(self):
        archive = self.tmpdir / "GNS3VM.Base.ARM64.1.2.3.zip"
        archive.write_text("existing archive")
        self.assertEqual(self.run_release(str(archive)), str(archive))
        self.assertEqual(archive.read_text(), "existing archive")
        self.assertFalse((self.root / "copy.log").exists())

    def test_unset_or_empty_tmpdir_defaults_to_tmp(self):
        for value in (None, ""):
            with self.subTest(tmpdir=value):
                if value is None:
                    self.environment.pop("TMPDIR", None)
                else:
                    self.environment["TMPDIR"] = value
                archive = "/tmp/GNS3VM.Base.ARM64.1.2.3.zip"
                self.assertEqual(self.run_release("source.zip"), archive)
                self.assertEqual((self.root / "copy.log").read_text().splitlines(),
                                 ["source.zip", archive])


if __name__ == "__main__":
    unittest.main()
