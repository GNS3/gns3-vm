#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Copyright (C) 2015 GNS3 Technologies Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import locale
import os
import sys
import time
import subprocess
import configparser
import urllib.request
from dialog import Dialog, PythonDialogBug

locale.setlocale(locale.LC_ALL, '')


def get_config():
    """
    Read the config
    """
    config = configparser.RawConfigParser()
    path = os.path.expanduser("~/.config/GNS3/gns3_server.conf")
    config.read([path], encoding="utf-8")
    return config


def gns3_version():
    """
    Return the GNS3 server version
    """
    try:
        return subprocess.check_output(["gns3server", "--version"]).strip().decode()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""



d = Dialog(dialog="dialog", autowidgetsize=True)
d.set_background_title("GNS3 {}".format(gns3_version()))


def mode():
    if d.yesno("This feature is for testers only. You can break your GNS3 install. Are you REALLY sure you want to continue?", yes_label="Exit (Safe option)", no_label="Continue") == d.OK:
        return
    d.msgbox("You have been warned...")
    code, tag = d.menu("Select the GNS3 version",
                       choices=[("Stable", "Last stable GNS3 version RECOMMENDED"),
                                ("Testing", "Next stable release"),
                                ("Unstable", "Totaly unstable version")])
    d.clear()
    if code == Dialog.OK:
        os.makedirs(os.path.expanduser("~/.config/GNS3"), exist_ok=True)
        with open(os.path.expanduser("~/.config/GNS3/gns3_release"), "w+") as f:
            if tag == "Stable":
                f.write("stable")
            elif tag == "Testing":
                f.write("testing")
            elif tag == "Unstable":
                f.write("unstable")
            else:
                assert False

        update(force=True)


def get_release():
    try:
        with open(os.path.expanduser("~/.config/GNS3/gns3_release")) as f:
            return f.read()
    except OSError:
        return "stable"


def update(force=False):
    if not force:
        if d.yesno("The server will reboot at the end of the update process. Continue?") != d.OK:
            return
    if get_release() == "stable":
        ret = os.system("curl https://raw.githubusercontent.com/GNS3/gns3-vm/master/scripts/update.sh |bash")
    elif get_release() == "testing":
        ret = os.system("curl https://raw.githubusercontent.com/GNS3/gns3-vm/master/scripts/update_testing.sh |bash")
    elif get_release() == "unstable":
        ret = os.system("curl https://raw.githubusercontent.com/GNS3/gns3-vm/unstable/scripts/update_unstable.sh |bash")
    if ret != 0:
        print("ERROR DURING UPGRADE PROCESS")
        time.sleep(15)


def vm_information():
    """
    Show IP, SSH settings....
    """

    try:
        with open('/etc/issue') as f:
            content = f.read()
    except FileNotFoundError:
        content = """Welcome to GNS3 appliance"""

    content += "\nRelease channel: " + get_release()

    try:
        d.msgbox(content)
    # If it's an scp command or any bugs
    except:
        os.execvp("bash", ['/bin/bash'])


def check_internet_connectivity():
    d.pause("Please wait...\n\n")
    try:
        response = urllib.request.urlopen('http://pypi.python.org/', timeout=5)
    except urllib.request.URLError as err:
        d.infobox("Can't connect to gns3.com: {}".format(str(err)))
        time.sleep(15)
        return
    d.infobox("Connection to internet: OK")
    time.sleep(2)


def keyboard_configuration():
    """
    Allow user to change the keyboard layout
    """
    os.system("/usr/bin/sudo dpkg-reconfigure keyboard-configuration")


def set_security():
    config = get_config()
    if d.yesno("Enable server authentication?") == d.OK:
        config.set("Server", "auth", True)
        (answer, text) = d.inputbox("Login?")
        if answer != d.OK:
            return
        config.set("Server", "user", text)
        (answer, text) = d.passwordbox("Password?")
        if answer != d.OK:
            return
        config.set("Server", "password", text)
    else:
        config.set("Server", "auth", False)

    with open(os.path.expanduser("~/.config/GNS3/gns3_server.conf"), 'w') as f:
        config.write(f)


def log():
    os.system("tail -f /var/log/upstart/gns3.log")


def edit_config():
    """
    Edit GNS3 configuration file
    """
    os.system("nano ~/.config/GNS3/gns3_server.conf")


vm_information()

try:
    while True:
        code, tag = d.menu("GNS3 {}".format(gns3_version()),
                           choices=[("Information", "Display VM information"),
                            ("Upgrade", "Upgrade GNS3"),
                            ("Shell", "Open a console"),
                            ("Security", "Configure authentication"),
                            ("Keyboard", "Change keyboard layout"),
                            ("Configure", "Edit server configuration (advanced users ONLY)"),
                            ("Log", "Show server log"),
                            ("Test", "Check internet connection"),
                            ("Version", "Select the GNS3 version"),
                            ("Reboot", "Reboot the VM"),
                            ("Shutdown", "Shutdown the VM")])
        d.clear()
        if code == Dialog.OK:
            if tag == "Shell":
                os.execvp("bash", ['/bin/bash'])
            elif tag == "Version":
                mode()
            elif tag == "Reboot":
                os.execvp("sudo", ['/usr/bin/sudo', "reboot"])
            elif tag == "Shutdown":
                os.execvp("sudo", ['/usr/bin/sudo', "poweroff"])
            elif tag == "Upgrade":
                update()
            elif tag == "Information":
                vm_information()
            elif tag == "Log":
                log()
            elif tag == "Configure":
                edit_config()
            elif tag == "Security":
                set_security()
            elif tag == "Keyboard":
                keyboard_configuration()
            elif tag == "Test":
                check_internet_connectivity()
except KeyboardInterrupt:
    sys.exit(0)
