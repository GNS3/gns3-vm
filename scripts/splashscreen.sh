#!/bin/bash
# Install boot splashscreen

set -e

sudo apt-get install -y plymouth-theme-script

set +e 
sudo mkdir -p /lib/plymouth/themes/gns3
set -e 

sudo chown -R gns3:gns3 /lib/plymouth/themes/gns3

cat > /lib/plymouth/themes/gns3/gns3.plymouth <<EOF
[Plymouth Theme]
Name=GNS3
Description=GNS3 Loading Screen
ModuleName=script
[script]
ImageDir=/lib/plymouth/themes/gns3
ScriptFile=/lib/plymouth/themes/gns3/gns3.script
EOF

curl "https://raw.githubusercontent.com/GNS3/gns3-vm/master/plymouth/logo_wo_bar.png" > /lib/plymouth/themes/gns3/logo_wo_bar.png

curl "https://raw.githubusercontent.com/GNS3/gns3-vm/master/plymouth/bar.png" > /lib/plymouth/themes/gns3/bar.png

curl "https://raw.githubusercontent.com/GNS3/gns3-vm/master/plymouth/end.png" > /lib/plymouth/themes/gns3/end.png


cat > /lib/plymouth/themes/gns3/gns3.script <<EOF
# Original script
# GPL V3 Licence
# https://github.com/dainok/unetlab/blob/master/plymouth/unetlab.script

# Setting the backgrounds
Window.SetBackgroundTopColor(1.0, 1.0, 1.0);
Window.SetBackgroundBottomColor(1.0, 1.0, 1.0);

# Load the logo
logo.image = Image("logo_wo_bar.png");

# Start of bar
bar_y = 351;
bar_x = 1057;
bar_width = 1052;

# Distance between the start of end image and the start of bar
end_bar_y = 138;

# Scaling during boot/shutdown
boot_scale = 3.84;      # 1 / max_progress
shutdown_scale = 1.10;   # 1 / min_progress

# Get scale factor
if (Window.GetWidth() > logo.image.GetWidth() && Window.GetHeight() > logo.image.GetHeight()) {
    # Screen is larger than logo
    scale = 1;
} else {
    # Screen is smaller than logo
    scale_x = Window.GetWidth() / logo.image.GetWidth();
    scale_y = Window.GetHeight() / logo.image.GetHeight();
    scale = Math.Min(scale_x, scale_y) * 0.95;
}

# Position the scaled logo in the center of the screen
logo.width = logo.image.GetWidth() * scale;
logo.height = logo.image.GetHeight() * scale;
logo.scaled = logo.image.Scale(logo.width, logo.height);
logo.x = Window.GetX() + Window.GetWidth() / 2 - logo.width / 2;
logo.y = Window.GetY() + Window.GetHeight() / 2 - logo.height / 2;
logo.z = 0;

# Print the logo
logo.sprite = Sprite();
logo.sprite.SetImage(logo.scaled);
logo.sprite.SetX(logo.x);
logo.sprite.SetY(logo.y);
logo.sprite.SetZ(logo.z);
logo.sprite.SetOpacity(1);

fun refresh_callback () {
    # Currently we do nothing here
}

Plymouth.SetRefreshFunction (refresh_callback);

#----------------------------------------- Progress Bar --------------------------------

# Load the bar
bar.image = Image("bar.png");
bar.height = bar.image.GetHeight() * scale;
bar.x = logo.x + logo.width * bar_x / logo.image.GetWidth();    # x = bar_x starts the bar (upper/left corner)
bar.y = logo.y + logo.height * bar_y / logo.image.GetHeight();  # y = bar_y starts the bar (upper/left corner)
bar.z = 2;

# Load the end of the bar
end.image = Image("end.png");
end.height = end.image.GetHeight() * scale;
end.y = (logo.y + logo.height * bar_y / logo.image.GetHeight()) - (end_bar_y * scale);
end.z = 3;

checkpoint = 0;
fun progress_callback (duration, progress) {
    if (Plymouth.GetMode() == "boot") {
        if (progress * boot_scale <= 1) {
            # Boot scale can lead to large bar
            bar.width = bar_width * scale * progress * boot_scale;
        }
    } else if (Plymouth.GetMode() == "shutdown") {
        if (1 - progress * shutdown_scale >= 0) {
            # Shutdown scale can lead to negative bar
            bar.width = bar_width * scale * (1 - progress * shutdown_scale);
        }
    } else {
        # suspend and resume
        bar.width = bar_width * scale;
    }

    if (checkpoint != progress) {
        # Position the scaled bar
        bar.scaled = bar.image.Scale(bar.width, bar.height);
        bar.sprite = Sprite();
        bar.sprite.SetImage(bar.scaled);
        bar.sprite.SetX(bar.x);
        bar.sprite.SetY(bar.y);
        bar.sprite.SetZ(bar.z);
        bar.sprite.SetOpacity(1);

        # Position the scaled end bar
        end.x = logo.x + logo.width * bar_x / logo.image.GetWidth() + bar.width - 1;   # Start at the end of the bar
        end.width = end.image.GetWidth() * scale;
        end.scaled = end.image.Scale(end.width, end.height);
        end.sprite = Sprite();
        end.sprite.SetImage(end.scaled);
        end.sprite.SetX(end.x);
        end.sprite.SetY(end.y);
        end.sprite.SetZ(end.z);
        end.sprite.SetOpacity(1);

        checkpoint = progress;
    }
}

    # Currently we do nothing here
Plymouth.SetBootProgressFunction(progress_callback);

#----------------------------------------- Quit --------------------------------

fun quit_callback () {
    if (Plymouth.GetMode() == "boot") {
        bar.width = bar_width * scale;
    } else if (Plymouth.GetMode() == "shutdown") {
        bar.width = 0;
    } else {
        # suspend and resume
        bar.width = bar_width * scale;
    }

    if (checkpoint != progress) {
        # Position the scaled bar
        bar.scaled = bar.image.Scale(bar.width, bar.height);
        bar.sprite = Sprite();
        bar.sprite.SetImage(bar.scaled);
        bar.sprite.SetX(bar.x);
        bar.sprite.SetY(bar.y);
        bar.sprite.SetZ(bar.z);
        bar.sprite.SetOpacity(1);

        # Position the scaled end bar
        end.x = logo.x + logo.width * bar_x / logo.image.GetWidth() + bar.width - 1;   # Start at the end of the bar
        end.width = end.image.GetWidth() * scale;
        end.scaled = end.image.Scale(end.width, end.height);
        end.sprite = Sprite();
        end.sprite.SetImage(end.scaled);
        end.sprite.SetX(end.x);
        end.sprite.SetY(end.y);
        end.sprite.SetZ(end.z);
        end.sprite.SetOpacity(1);

        checkpoint = progress;
    }
}

Plymouth.SetQuitFunction(quit_callback);

#----------------------------------------- Message --------------------------------

message_sprite = Sprite();
message_sprite.SetPosition(1332, 567, 10000);

fun message_callback (text) {
    my_image = Image.Text(text, 1, 1, 1);
    message_sprite.SetImage(my_image);
}

Plymouth.SetMessageFunction(message_callback);
EOF

sudo chown -R root:root /lib/plymouth/themes/gns3

sudo update-alternatives --install /lib/plymouth/themes/default.plymouth default.plymouth /lib/plymouth/themes/gns3/gns3.plymouth 100
 
sudo update-initramfs -u
