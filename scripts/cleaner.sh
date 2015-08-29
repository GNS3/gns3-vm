sudo apt-get purge -y vim-common
sudo apt-get purge -y fonts-ubuntu-font-family-console
sudo apt-get purge -y linux-headers-generic
sudo apt-get purge -y linux-headers-virtual
sudo apt-get purge -y vim-runtime
sudo apt-get purge -y screen
sudo apt-get purge -y tmux
sudo apt-get purge -y memtest86+
sudo apt-get purge -y usbutils
sudo apt-get purge -y linux-firmware
sudo apt-get purge -y wpasupplicant
sudo apt-get purge -y wireless-tools
sudo apt-get purge -y wireless-regdb
sudo apt-get purge -y xauth
sudo apt-get purge -y ppp
sudo apt-get purge -y logrotate
sudo apt-get purge -y w3m
sudo apt-get purge -y python2.7-minimal
sudo apt-get purge -y man-db
sudo apt-get purge -y sgml-base
sudo apt-get purge -y mtr-tiny
sudo apt-get purge -y rsyslog
sudo apt-get purge -y lshw
sudo apt-get purge -y geoip-database
sudo apt-get purge -y groff-base
sudo apt-get purge -y fuse
sudo apt-get purge -y update-manager-core
sudo apt-get purge -y ntpdate
sudo apt-get purge -y apport
sudo apt-get purge -y bc
sudo apt-get purge -y aptitude
sudo apt-get purge -y libtext-iconv-perl
sudo apt-get purge -y libpython2.7-minimal
sudo apt-get purge -y libapparmor-perl
sudo apt-get purge -y liblocale-gettext-perl
sudo apt-get purge -y libtext-charwidth-perl
sudo apt-get purge -y unattended-upgrades
sudo apt-get purge -y ntfs-3g
sudo apt-get purge -y manpages
sudo apt-get purge -y xkb-data
sudo apt-get purge -y krb5-locales
sudo apt-get purge -y gcc-4.9
sudo apt-get purge -y git
sudo apt-get purge -y cmake-data
sudo apt-get purge -y cpp-4.9
sudo apt-get purge -y language-pack-en
sudo apt-get purge -y gcc
sudo apt-get purge -y gcc-4.8
sudo apt-get purge -y rsyslog
sudo apt-get purge -y language-pack-gnome-en-base

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

# Setup zerofree for disk compaction
sudo mv /tmp/init_zerofree /etc/init.d/zerofree
sudo chown root:root /etc/init.d/zerofree
sudo chmod 744 /etc/init.d/zerofree
sudo update-rc.d zerofree defaults 61
sudo mv /etc/rc0.d/K61zerofree /etc/rc0.d/S61zerofree
sudo mv /etc/rc6.d/K61zerofree /etc/rc6.d/S61zerofree
sudo touch /zerofree

