sudo apt-get purge -y vim-common fonts-ubuntu-font-family-console linux-headers-generic linux-headers-virtual vim-runtime screen tmux memtest86+ usbutils linux-firmware wpasupplicant wireless-tools wireless-regdb xauth ppp logrotate w3m python2.7-minimal man-db sgml-base mtr-tiny rsyslog lshw geoip-database groff-base fuse update-manager-core ntpdate apport bc aptitude libtext-iconv-perl libpython2.7-minimal libapparmor-perl liblocale-gettext-perl libtext-charwidth-perl unattended-upgrades ntfs-3g manpages xkb-data krb5-locales gcc-4.9 git cmake-data cpp-4.9 language-pack-en gcc gcc-4.8 rsyslog language-pack-gnome-en-base

# Purge old kernels
dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | xargs sudo apt-get -y purge

dpkg -l 'linux-headers-*' |grep '^ii'|sed 's/^ii[ ]*//'|cut -f1 -d' '| xargs sudo apt-get -y purge
dpkg -l 'linux-image-extra-*' |grep '^ii'|sed 's/^ii[ ]*//'|cut -f1 -d' '| xargs sudo apt-get -y purge


# Purge locale
sudo rm -Rf /usr/share/locale/*
sudo locale-gen --purge --lang en_US

# Tools for cleaning the disk
sudo apt-get install -y zerofree

sudo apt-get -y autoremove
sudo apt-get -y clean

sudo rm -fr /var/lib/apt/lists/*
sudo rm -fr /var/cache/apt/*
sudo rm -fr /var/cache/debconf/*
sudo rm -fr /var/cache/man/*
sudo rm -Rf /var/log/installer/*
sudo rm -Rf /usr/share/doc
sudo rm -Rf /var/lib/docker/devicemapper

sudo pip3 uninstall -y gns3-server

# Setup zerofree for disk compaction
sudo mv /tmp/init_zerofree /etc/init.d/zerofree
sudo chown root:root /etc/init.d/zerofree
sudo chmod 744 /etc/init.d/zerofree
sudo update-rc.d zerofree defaults 61
sudo mv /etc/rc0.d/K61zerofree /etc/rc0.d/S61zerofree
sudo mv /etc/rc6.d/K61zerofree /etc/rc6.d/S61zerofree
sudo touch /zerofree

