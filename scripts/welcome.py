#! /usr/bin/env python3

import locale
import os
from dialog import Dialog, PythonDialogBug

locale.setlocale(locale.LC_ALL, '')

d = Dialog(dialog="dialog", autowidgetsize=True)
d.set_background_title("GNS3")


try:
    with open('/etc/issue') as f:
        content = f.read()
except FileNotFoundError:
    content = """Welcome to GNS3 appliance"""

try:
    d.msgbox(content)
# If it's an scp command or any bugs
except:
    os.execvp("bash", ['/bin/bash'])

while True:
    code, tag = d.menu("Some text that will be displayed above the menu entries",
                       choices=[("Update", "Update GNS3"),
                        ("Shell", "Open a console"),
                        ("Reboot", "Reboot the VM"),
                        ("Shutdown", "Shutdown the VM")])
    d.clear()
    if code == Dialog.OK:
        if tag == "Shell":
            os.execvp("bash", ['/bin/bash'])
        elif tag == "Reboot":
            os.execvp("sudo", ['/usr/bin/sudo', "reboot"])
        elif tag == "Shutdown":
            os.execvp("sudo", ['/usr/bin/sudo', "poweroff"])
        elif tag == "Update":
            os.system("curl https://raw.githubusercontent.com/GNS3/gns3-packer/master/scripts/update.sh |bash && sudo reboot")
