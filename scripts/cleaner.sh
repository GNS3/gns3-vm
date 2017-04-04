sudo apt-get purge -y --force-yes vim-common
sudo apt-get purge -y --force-yes fonts-ubuntu-font-family-console
sudo apt-get purge -y --force-yes linux-headers-generic
sudo apt-get purge -y --force-yes linux-headers-virtual
sudo apt-get purge -y --force-yes vim-runtime
sudo apt-get purge -y --force-yes screen
sudo apt-get purge -y --force-yes tmux
sudo apt-get purge -y --force-yes memtest86+
sudo apt-get purge -y --force-yes usbutils
sudo apt-get purge -y --force-yes linux-firmware
sudo apt-get purge -y --force-yes wpasupplicant
sudo apt-get purge -y --force-yes wireless-tools
sudo apt-get purge -y --force-yes wireless-regdb
sudo apt-get purge -y --force-yes ppp
sudo apt-get purge -y --force-yes w3m
sudo apt-get purge -y --force-yes python2.7-minimal
sudo apt-get purge -y --force-yes man-db
sudo apt-get purge -y --force-yes sgml-base
sudo apt-get purge -y --force-yes mtr-tiny
sudo apt-get purge -y --force-yes lshw
sudo apt-get purge -y --force-yes geoip-database
sudo apt-get purge -y --force-yes groff-base
sudo apt-get purge -y --force-yes fuse
sudo apt-get purge -y --force-yes update-manager-core
sudo apt-get purge -y --force-yes ntpdate
sudo apt-get purge -y --force-yes apport
sudo apt-get purge -y --force-yes bc
sudo apt-get purge -y --force-yes aptitude
sudo apt-get purge -y --force-yes libtext-iconv-perl
sudo apt-get purge -y --force-yes libpython2.7-minimal
sudo apt-get purge -y --force-yes libapparmor-perl
sudo apt-get purge -y --force-yes libtext-charwidth-perl
sudo apt-get purge -y --force-yes unattended-upgrades
sudo apt-get purge -y --force-yes ntfs-3g
sudo apt-get purge -y --force-yes manpages
sudo apt-get purge -y --force-yes krb5-locales
sudo apt-get purge -y --force-yes git
sudo apt-get purge -y --force-yes cmake-data
sudo apt-get purge -y --force-yes cpp-4.9
sudo apt-get purge -y --force-yes language-pack-en
sudo apt-get purge -y --force-yes language-pack-gnome-en-base

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
sudo touch /zerofree

sudo rm -rf /tmp/*
