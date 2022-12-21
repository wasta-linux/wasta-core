#!/bin/bash

# ==============================================================================
# wasta-core: app-installs.sh
# ==============================================================================

# ------------------------------------------------------------------------------
# Check to ensure running as root
# ------------------------------------------------------------------------------
#   No fancy "double click" here because normal user should never need to run
if [ $(id -u) -ne 0 ]
then
    echo
    echo "You must run this script with sudo." >&2
    echo "Exiting...."
    sleep 5s
    exit 1
fi

# ------------------------------------------------------------------------------
# Function: aptError
# ------------------------------------------------------------------------------
aptError () {
    if [ "$AUTO" ];
    then
        echo
        echo "*** ERROR: apt-get command failed. You may want to re-run!"
        echo
    else
        echo
        echo "     --------------------------------------------------------"
        echo "     'APT' Error During Update / Installation"
        echo "     --------------------------------------------------------"
        echo
        echo "     An error was encountered with the last 'apt' command."
        echo "     You should close this script and re-start it, or"
        echo "     correct the error manually before proceeding."
        echo
        read -p "     Press any key to proceed..."
        echo
   fi
}

# ------------------------------------------------------------------------------
# Initial Setup
# ------------------------------------------------------------------------------

echo
echo "*** Script Entry: app-installs.sh"
echo
# Setup variables for later reference
DIR=/usr/share/wasta-core
SERIES=$(lsb_release -sc)
ARCH=$(uname -m)

# if 'auto' parameter passed, run non-interactively
if [ "$1" == "auto" ];
then
    AUTO="auto"
    
    # needed for apt-get
    YES="--yes"
    DEBIAN_NONINTERACTIVE="env DEBIAN_FRONTEND=noninteractive"

    # needed for gdebi
    INTERACTIVE="-n"

    # needed for dpkg-reconfigure
    DPKG_FRONTEND="--frontend=noninteractive"
else
    AUTO=""
    YES=""
    DEBIAN_NONINTERACTIVE=""
    INTERACTIVE=""
    DPKG_FRONTEND=""
fi

# ------------------------------------------------------------------------------
# Configure sources and update settings and do update
# ------------------------------------------------------------------------------
echo
echo "*** Making adjustments to software repository sources"
echo

APT_SOURCES=/etc/apt/sources.list

if ! [ -e $APT_SOURCES.wasta ];
then
    APT_SOURCES=/etc/apt/sources.list
    APT_SOURCES_D=/etc/apt/sources.list.d
else
    # wasta-offline active: adjust apt file locations
    echo
    echo "*** wasta-offline active, applying repository adjustments to /etc/apt/sources.list.wasta"
    echo
    APT_SOURCES=/etc/apt/sources.list.wasta
    if [ -e /etc/apt/sources.list.d ];
    then
        echo
        echo "*** wasta-offline 'offline and internet' mode detected"
        echo
        # wasta-offline "offline and internet mode": no change to sources.list.d
        APT_SOURCES_D=/etc/apt/sources.list.d
    else
        echo
        echo "*** wasta-offline 'offline only' mode detected"
        echo
        # wasta-offline "offline only mode": change to sources.list.d location
        APT_SOURCES_D=/etc/apt/sources.list.d.wasta
    fi
fi

# first backup $APT_SOURCES in case something goes wrong
# delete $APT_SOURCES.save if older than 30 days
find /etc/apt  -maxdepth 1 -mtime +30 -iwholename $APT_SOURCES.save -exec rm {} \;

if ! [ -e $APT_SOURCES.save ];
then
    cp $APT_SOURCES $APT_SOURCES.save
fi

# add LibreOffice 7.2 PPA
#if ! [ -e $APT_SOURCES_D/wasta-linux-ubuntu-libreoffice-7-2-$SERIES.list ];
#then
#    echo
#    echo "*** Adding LibreOffice 7.2 PPA"
#    echo
#    echo "deb http://ppa.launchpadcontent.net/wasta-linux/libreoffice-7-2/ubuntu $SERIES main" | \
#        tee $APT_SOURCES_D/wasta-linux-ubuntu-libreoffice-7-2-$SERIES.list
#    echo "# deb-src http://ppa.launchpadcontent.net/wasta-linux/libreoffice-7-2/ubuntu $SERIES main" | \
#        tee -a $APT_SOURCES_D/wasta-linux-ubuntu-libreoffice-7-2-$SERIES.list
#else
#    # found, but ensure LibreOffice PPA ACTIVE (user could have accidentally disabled)
#    # DO NOT match any lines ending in #wasta
#    sed -i -e '/#wasta$/! s@.*\(deb http[s]*://ppa.launchpadcontent.net\)@\1@' \
#       $APT_SOURCES_D/wasta-linux-ubuntu-libreoffice-7-2-$SERIES.list
#fi

#echo
#echo "*** Removing Older LibreOffice PPAs"
#echo
#rm -f $APT_SOURCES_D/wasta-linux-ubuntu-libreoffice-7-1*

# Add Skype repository (only supports amd64)
if [ $ARCH == 'x86_64' ];
then
    if ! [ -e $APT_SOURCES_D/skype-stable.list ];
    then
        echo
        echo "*** Adding Skype Repository"
        echo

        echo "deb https://repo.skype.com/deb stable main" | \
            tee $APT_SOURCES_D/skype-stable.list
    fi
fi

# add Keyman PPA
if ! [ -e $APT_SOURCES_D/keymanapp-ubuntu-keyman-$SERIES.list ];
then
    echo
    echo "*** Adding Keyman PPA"
    echo
    echo "deb http://ppa.launchpadcontent.net/keymanapp/keyman/ubuntu $SERIES main" | \
        tee $APT_SOURCES_D/keymanapp-ubuntu-keyman-$SERIES.list
    echo "# deb-src http://ppa.launchpadcontent.net/keymanapp/keyman/ubuntu $SERIES main" | \
        tee -a $APT_SOURCES_D/keymanapp-ubuntu-keyman-$SERIES.list
 else
     # found, but ensure Keyman PPA ACTIVE (user could have accidentally disabled)
     # DO NOT match any lines ending in #wasta
     sed -i -e '/#wasta$/! s@.*\(deb http[s]*://ppa.launchpadcontent.net\)@\1@' \
        $APT_SOURCES_D/keymanapp-ubuntu-keyman-$SERIES.list
fi

apt-get update

LASTERRORLEVEL=$?
if [ "$LASTERRORLEVEL" -ne "0" ];
then
    aptError
fi

# ------------------------------------------------------------------------------
# Upgrade ALL
# ------------------------------------------------------------------------------

echo
echo "*** Install All Updates"
echo

$DEBIAN_NONINERACTIVE apt-get $YES dist-upgrade

LASTERRORLEVEL=$?
if [ "$LASTERRORLEVEL" -ne "0" ];
then
    aptError
fi

# ------------------------------------------------------------------------------
# Standard package installs for all systems
# ------------------------------------------------------------------------------

echo
echo "*** Standard Installs"
echo

# aisleriot: solitare game
# adb: terminal - communicate to Android devices
# apt-rdepends: reverse dependency lookup
# audacity lame: audio editing
# bloom-desktop art-of-reading3: sil bloom N/A for 22.04
# bookletimposer: pdf booklet / imposition tool
# brasero: CD/DVD burner
# calibre: e-book reader, utility
# catfish: more in-depth search than nemo gives (gnome-search-tool not available)
# cheese: webcam recorder, picture taker
# cifs-utils: "common internet filesystem utils" for fileshare utilities, etc.
# curl: terminal - download utility
# dconf-cli dconf-editor: gives tools for making settings adjustments
# debconf-utils: needed for debconf-get-selections, etc. for debconf configure
# diodon: clipboard manager
# dos2unix: terminal - convert line endings of files to / from windows to unix
# easytag: GUI ID3 tag editor
# exfat-fuse: compatibility for exfat formatted disks
# extundelete: terminal - restore deleted files
# firefox-esr: 22.04+ we default to this over the snap version
#   webext-ublock-origin-firefox: ublock origin for firefox
# flatpak
# font-manager: GUI for managing fonts
# fonts-crosextra-caladea: metrically compatible with "Cambria"
# fonts-crosextra-carlito: metrically compatible with "Calibri"
# fonts-sil-*: standard SIL fonts
# gcolor3: color pickerg
# gddrescue: data recovery tool
# gdebi: graphical .deb installer
# gimp: advanced graphics editor
# git: terminal - command-line git
# goldendict goldendict-wordnet: more advanced dictionary/thesaurus tool than artha
# gnome-calculator
# gnome-clocks: multi-timezone clocks, timers, alarms
# gnome-font-viewer: better than "font-manager" for just viewing a font file.
# gnome-logs: GUI log viewer
# gnome-maps: GUI map viewer
# gnome-nettool: network tool GUI (traceroute, lookup, etc)
# gnome-screenshot: GUI
# gnome-software: GUI allows deb, flatpak, snap integration (no PPA or 3rd party
#   deb repos however)
#   gnome-software-plugin-flatpak
#   gnome-software-plugin-snap
# gnome-system-monitor: GUI
# gparted: GUI partition manager
# grsync: GUI rsync tool
# gucharmap: gnome character map (traditional)
# gufw: GUI for "uncomplicated firewall"
# hardinfo: system profiler
# hddtemp: terminal - harddrive temp checker N/A 22.04
# hfsprogs: for apple hfs compatiblity
# hplip hplip-plugin: hp printer utility and proprietary plugin
# htop: process browser
# httrack: website download utility
# imagemagick: terminal - image resizing, etc. (needed for nemo resize action)
# inkscape: vector graphics editor
# inotify-tools: terminal - watch for file changes
# iperf3: terminal - network bandwidth measuring
# keepassxc: password manager (xc is the community port that is more up to date)
# keyman: keyman keyboard app
# klavaro: typing tutor
# libdvd-pkg: enables DVD playback (downloads and installs libdvdcss2)
# libreoffice: install the full meta-package
# libreoffice-sdbc-hsqldb: (pre-firebird) db backend for LO base
# libtext-pdf-perl: provides pdfbklt (make A5 booklet from pdf)
# meld: graphical text file compare utility
# mkisofs: teminal - this version (from cdrtools source package) allows ISOs
#   > 4GB in size. Alternative version from main repos (genisoimage package)
#   does NOT allow this. Included in the wasta-applications ppa
# modem-manager-gui: Check balance, top up, check signal strength, etc.
# mtp-tools: media-transfer-protocol tools: needed for smartphones
# ncdu: terminal - ncurses disk usage analyzer tool
# neofetch: terminal - displays system info
# nethogs: terminal - network monitor showing per application net usage
# net-tools: terminal - basic utilities like ifconfig
# pandoc: terminal - general markup converter
# pinta: MS Paint alternative: more simple for new users than gimp
# pngcrush: terminal - png size reducer
# qt5-style-plugins: needed for qt5 / gtk theme compatibility
# redshift-gtk: redshift for blue light reduction
# rhythmbox: music manager
# shotcut: video editor
# shotwell: photo editor / manager (can edit single files easily)
# shutter: GUI - powerful screenshot tool
# silcc: terminal - SIL consistent changes  N/A 22.04
# simplescreenrecorder: screen recorder
# soundconverter: convert audio formats
# sound-juicer: rip CDs
# ssh: terminal - remote access
# synaptic: more advanced package manager
#   apt-xapian-index: for synaptic indexing
# sysstat: terminal - provides sar: system activity reporter
# teckit: terminal - SIL teckit
# testdisk: terminal - photorec tool for recovery of deleted files
# thunderbird xul-ext-lightning: GUI email client
# tldr: terminal - gives 'tldr' summary of manpages
# tlp: laptop power savings
# traceroute: terminal
# traffic-cop: graphical frontend to limit bandwidth per app
# ttf-mscorefonts-installer: installs standard Microsoft fonts
# ubiquity-frontend-gtk: add here so not needed to be downloaded by
#   wasta-remastersys or if needs to be updated by app-adjustments.sh
# ubiquity-slideshow-wasta:
# ubuntu-restricted-extras: mp3, flash, etc.
# uget uget-integrator: GUI download manager (DTA in Firefox abandoned)
# uptimed: terminal - provides "uprecords"
# vim-tiny: terminal - text editor (don't want FULL vim or else in main menu)
# vlc: play any audio or video files
# wasta-backup: GUI for rdiff-backup
# wasta-ibus: wasta customization of ibus
# wasta-menus: applicationmenu limiting system
# wasta-offline wasta-offline-setup: offline updates and installs
# wasta-papirus papirus-icon-theme: more 'modern' icon theme
# wasta-remastersys: create ISO of system
# wasta-resources-core: wasta-core documentation and resources
# wavemon: terminal - for wirelesssudo su network diagonstics
# webp-pixbuf-loader: adds support for webp images (in eye-of-gnome etc)
# xmlstarlet: terminal - reading / writing to xml files
# xsltproc: terminal - xslt, xml conversion program
# youtube-dl: terminal - youtube / video downloads
# zim: wiki style note taking app

$DEBIAN_NONINERACTIVE bash -c "apt-get $YES install \
    aisleriot \
    adb \
    apt-rdepends \
    audacity lame \
    bookletimposer \
    brasero \
    calibre \
    catfish \
    cheese \
    cifs-utils \
    curl \
    dconf-editor dconf-cli \
    debconf-utils \
    diodon \
    dos2unix \
    easytag \
    exfat-fuse \
    extundelete \
    firefox-esr \
        webext-ublock-origin-firefox \
    flatpak \
    font-manager \
    fonts-crosextra-caladea \
    fonts-crosextra-carlito \
    fonts-sil-andika \
        fonts-sil-andika-compact \
        fonts-sil-annapurna \
        fonts-sil-charis \
        fonts-sil-charis-compact \
        fonts-sil-doulos \
        fonts-sil-doulos-compact \
        fonts-sil-gentiumplus \
        fonts-sil-gentiumplus-compact \
    gcolor3 \
    gddrescue \
    gdebi \
    gimp \
    git \
    goldendict \
        goldendict-wordnet \
    gnome-calculator \
    gnome-clocks \
    gnome-font-viewer \
    gnome-logs \
    gnome-maps \
    gnome-nettool \
    gnome-screenshot \
    gnome-software \
        gnome-software-plugin-flatpak \
        gnome-software-plugin-snap \
    gnome-system-monitor \
    gparted \
    grsync \
    gucharmap \
    gufw \
    hardinfo \
    hfsprogs \
    hplip
        hplip-plugin \
    htop \
    httrack \
    imagemagick \
    inkscape \
    inotify-tools \
    iperf3 \
    keepassxc \
    keyman \
    klavaro \
    libdvd-pkg \
    libreoffice \
        libreoffice-sdbc-hsqldb \
    libtext-pdf-perl \
    meld \
    mkisofs \
    modem-manager-gui \
    mtp-tools \
    ncdu \
    neofetch \
    nethogs \
    net-tools \
    pandoc \
    pinta \
    pngcrush \
    qt5-style-plugins \
    redshift-gtk \
    rhythmbox \
    shotcut \
    shotwell \
    shutter \
    simplescreenrecorder \
    soundconverter \
    sound-juicer \
    ssh \
    synaptic apt-xapian-index \
    sysstat \
    teckit \
    testdisk \
    thunderbird xul-ext-lightning \
    tldr \
    tlp \
    traceroute \
    traffic-cop \
    ttf-mscorefonts-installer \
    ubiquity-frontend-gtk ubiquity-slideshow-wasta \
    ubuntu-restricted-extras \
    uget uget-integrator \
    uptimed \
    vim-tiny \
    vlc \
    wasta-backup \
    wasta-ibus \
    wasta-menus \
    wasta-offline wasta-offline-setup \
    wasta-papirus papirus-icon-theme \
    wasta-resources-core \
    wavemon \
    webp-pixbuf-loader \
    xmlstarlet \
    xsltproc \
    youtube-dl \
    zim \
    "

LASTERRORLEVEL=$?
if [ "$LASTERRORLEVEL" -ne "0" ];
then
    aptError
fi


# ------------------------------------------------------------------------------
# Default packages not available on all arches
# ------------------------------------------------------------------------------
if [ "${ARCH}" == "x86_64" ]; then
    $DEBIAN_NONINERACTIVE bash -c "apt-get $YES install \
        wasta-remastersys \
        "
fi

# ------------------------------------------------------------------------------
# Language Support Files: install
# ------------------------------------------------------------------------------
echo
echo "*** Installing Language Support Files"
echo

SYSTEM_LANG=$(locale | grep LANG= | cut -d= -f2 | cut -d_ -f1)
INSTALL_APPS=$(check-language-support -l $SYSTEM_LANG)

apt-get $YES install $INSTALL_APPS

# ------------------------------------------------------------------------------
# Enable Flathub
# ------------------------------------------------------------------------------
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# ------------------------------------------------------------------------------
# Flatpak Installs
# ------------------------------------------------------------------------------
flatpak install --system flathub org.sil.Bloom

# 2022-11-22 rik: UPDATE: I got an updated hplip from a ppa that also
#   includes the hplip-plugin package (installed above).
# ------------------------------------------------------------------------------
# Install hp-plugin (non-interactive)
# ------------------------------------------------------------------------------
# Install hp-plugin automatically: needed by some HP printers such as black
#   HP m127 used by SIL Ethiopia. Don't display output to confuse user.

#echo
#echo "*** Installing hp-plugin"
#    yes | hp-plugin -p $DIR/resources/hp-plugin-$SERIES/ >/dev/null 2>&1
#echo "*** hp-plugin install complete"
#echo

# ------------------------------------------------------------------------------
# wasta-remastersys conf updates
# ------------------------------------------------------------------------------
WASTA_REMASTERSYS_CONF=/etc/wasta-remastersys/wasta-remastersys.conf
if [ -e "$WASTA_REMASTERSYS_CONF" ];
then
    # change to wasta-linux splash screen
    sed -i -e 's@SPLASHPNG=.*@SPLASHPNG="/usr/share/wasta-core/resources/wasta-linux-vga.png"@' \
        "$WASTA_REMASTERSYS_CONF"
    
    # set default CD Label and ISO name
    WASTA_ID="$(sed -n "\@^ID=@s@^ID=@@p" /etc/wasta-release)"
    WASTA_VERSION="$(sed -n "\@^VERSION=@s@^VERSION=@@p" /etc/wasta-release)"
    if [ $ARCH == 'x86_64' ];
    then
        WASTA_ARCH="64bit"
    else
        WASTA_ARCH="32bit"
    fi
    WASTA_DATE=$(date +%F)

    #shortening CUSTOMISO since if it is too long wasta-remastersys will fail
    sed -i -e "s@LIVECDLABEL=.*@LIVECDLABEL=\"$WASTA_ID $WASTA_VERSION $WASTA_ARCH\"@" \
           -e "s@CUSTOMISO=.*@CUSTOMISO=\"WL-$WASTA_VERSION-$WASTA_ARCH.iso\"@" \
           -e "s@SLIDESHOW=.*@SLIDESHOW=wasta@" \
        "$WASTA_REMASTERSYS_CONF"
fi

# ------------------------------------------------------------------------------
# Reconfigure libdvd-pkg to get libdvdcss2 installed
# ------------------------------------------------------------------------------
# during the install of libdvd-pkg it can't in turn install libdvdcss2 since
#   another dpkg process is already active, so need to do it again
dpkg-reconfigure $DPKG_FRONTEND libdvd-pkg

# ------------------------------------------------------------------------------
# Clean up apt cache
# ------------------------------------------------------------------------------
# not doing since we may want those packages for wasta-offline
#apt-get autoremove
#apt-get autoclean

echo
echo "*** Script Exit: app-installs.sh"
echo

exit 0
