sudo apt-get purge -y vim-common fonts-ubuntu-font-family-console linux-headers-generic linux-headers-virtual vim-runtime screen tmux memtest86+ usbutils linux-firmware wpasupplicant wireless-tools wireless-regdb xauth ppp logrotate w3m python2.7-minimal man-db sgml-base mtr-tiny rsyslog lshw geoip-database groff-base fuse update-manager-core ntpdate apport bc aptitude libtext-iconv-perl libpython2.7-minimal libapparmor-perl liblocale-gettext-perl libtext-charwidth-perl unattended-upgrades ntfs-3g manpages xkb-data krb5-locales gcc-4.9 git cmake-data cpp-4.9 language-pack-en gcc gcc-4.8 rsyslog

# Purge old kernels
dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | xargs sudo apt-get -y purge

dpkg -l 'linux-headers-*' |grep '^ii'|sed 's/^ii[ ]*//'|cut -f1 -d' '| xargs sudo apt-get -y purge



# Purge locale
sudo rm -Rf /usr/share/locale/*
sudo locale-gen --purge --lang en_US

# Tools for cleaning the disk
sudo apt-get install -y zerofree

sudo apt-get -y autoremove 
sudo apt-get -y clean

sudo rm -fr /var/lib/apt/lists/*
sudo rm -fr /var/cache/apt/*
sudo rm -Rf /var/log/installer/*
sudo rm -Rf /usr/share/doc
