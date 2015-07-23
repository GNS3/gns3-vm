#!/usr/bin/env python
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


"""
Tool for manipulating OVA
"""

import sys
import tarfile

def view(path):
    """
    Display the content of the OVA file for human
    """
    with tarfile.open(path) as tar:
        print("=> Files in .ova:")
        for member in tar.getmembers():
            print("* " + member.name)
        print("")
        for member in tar.getmembers():
            if member.name.endswith(".ovf") or member.name.endswith(".mf"):
                print("=> Content of " + member.name + ":")
                print(tar.extractfile(member).read().decode("utf-8"))
                print("")


def main():
    view(sys.argv[1])

if __name__ == '__main__':
    main()
