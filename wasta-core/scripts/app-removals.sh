#!/bin/bash

# ==============================================================================
# wasta-core: app-removals.sh
#
#   This script will remove apps deemed "unnecessary" for default users.
#
#   2019-11-24 rik: initial focal script
#   2020-07-20 rik: separate out snapd and gnome-software removals so users
#       could opt to NOT purge them
#
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
# Initial Setup
# ------------------------------------------------------------------------------

echo
echo "*** Script Entry: app-removals.sh"
echo
# Setup Diretory for later reference
DIR=/usr/share/wasta-core

# if 'auto' parameter passed, run non-interactively
if [ "$1" == "auto" ];
then
    AUTO="auto"
    
    # needed for apt-get
    YES="--yes"
else
    AUTO=""
    YES=""
fi

# ------------------------------------------------------------------------------
# Ensure lightdm installed (so can remove gdm3 below)
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Base Packages to remove for all systems
# ------------------------------------------------------------------------------

echo
echo "*** Removing Unwanted Applications"
echo

# blueman: not sure why cinnamon has this listed as a 'recommends'
# checkbox-common:
#   - but removing it will remove ubuntu-desktop so not removing
# deja-dup: we use wasta-backup
# dkms: if installed then ubiquity will fail when installing shim-signed
#   because will need interaction to setup secureboot keys
# empathy: chat client
# fonts-noto-cjk: conflicts with font-manager: newer font-manager from ppa
#   handles it, but it is too different to use
# fonts-*: non-english fonts
#   ttf-* fonts: non-english font families
# gnome-software: high RAM and CPU use, doesn't display SIL / Wasta apps
# gnome-sushi:confusing for some
# landscape-client-ui-install: pay service only for big corporations
# mpv: media player - not sure how this got installed
# totem: not needed as vlc handles all video/audio
# transmission: normal users doing torrents probably isn't preferred
# unity-webapps-common: amazon shopping lens, etc.
# webbrowser-app: ubuntu web browser brought in by unity-tweak-tool
# whoopsie: ubuntu crash report system but hangs shutdown

# 2016-05-04 rik: if attempting to remove a package that doesn't exist (such
#   as can happen when using wasta-offline "offline only mode") apt-get purge
#   will error and not remove anything.  So instead found this way to do it:
#       http://superuser.com/questions/518859/ignore-packages-that-are-not-currently-installed-when-using-apt-get-remove
pkgToRemoveListFull="\
    blueman \
    deja-dup \
    dkms \
    empathy-common \
    fonts-beng* \
        fonts-deva* \
        fonts-gargi \
        fonts-gubbi \
        fonts-gujr* \
        fonts-guru* \
        fonts-indic \
        fonts-kacst* \
        fonts-kalapi \
        fonts-knda \
        fonts-khmeros-core \
        fonts-lao \
        fonts-lklug-sinhala \
        fonts-lohit* \
        fonts-mlym \
        fonts-nakula \
        fonts-navilu \
        fonts-nanum \
        fonts-noto-* \
        fonts-orya* \
        fonts-pagul \
        fonts-sahadeva \
        fonts-samyak* \
        fonts-sarai \
        fonts-sil-padauk \
        fonts-smc* \
        fonts-takao-pgothic \
        fonts-taml \
        fonts-telu* \
        fonts-tibetan-machine \
        fonts-*tlwg* \
        ttf-indic-fonts-core \
        ttf-kacst-one \
        ttf-khmeros-core \
        ttf-punjabi-fonts \
        ttf-takao-pgothic \
        ttf-thai-tlwg \
        ttf-unfonts-core \
        ttf-wqy-microhei \
    gnome-sushi unoconv \
    landscape-client-ui-install \
    mpv \
    totem \
        totem-common \
        totem-plugins \
    transmission transmission-common \
    unity-webapps-common \
    webbrowser-app \
    whoopsie"

pkgToRemoveList=""
for pkgToRemove in $(echo $pkgToRemoveListFull); do
  $(dpkg --status $pkgToRemove &> /dev/null)
  # errno:0 = exists. errno:1 = not exists. errno:2 = invalid name (eg: with *)
  errno=$?
  if [[ $errno -eq 0 ]] || [[ $errno -eq 2 ]]; then
    pkgToRemoveList="$pkgToRemoveList $pkgToRemove"
  fi
done

apt-get $YES purge $pkgToRemoveList

# ------------------------------------------------------------------------------
# separately remove 'snapd' since some users may want to keep
# ------------------------------------------------------------------------------

pkgToRemoveListFull="snapd"
pkgToRemoveList=""
for pkgToRemove in $(echo $pkgToRemoveListFull); do
  $(dpkg --status $pkgToRemove &> /dev/null)
  # errno:0 = exists. errno:1 = not exists. errno:2 = invalid name (eg: with *)
  errno=$?
  if [[ $errno -eq 0 ]] || [[ $errno -eq 2 ]]; then
    pkgToRemoveList="$pkgToRemoveList $pkgToRemove"
  fi
done

apt-get $YES purge $pkgToRemoveList

# ------------------------------------------------------------------------------
# separately remove 'gnome-software' since some users may want to keep
# ------------------------------------------------------------------------------

pkgToRemoveListFull="gnome-software"
pkgToRemoveList=""
for pkgToRemove in $(echo $pkgToRemoveListFull); do
  $(dpkg --status $pkgToRemove &> /dev/null)
  # errno:0 = exists. errno:1 = not exists. errno:2 = invalid name (eg: with *)
  errno=$?
  if [[ $errno -eq 0 ]] || [[ $errno -eq 2 ]]; then
    pkgToRemoveList="$pkgToRemoveList $pkgToRemove"
  fi
done

apt-get $YES purge $pkgToRemoveList

# ------------------------------------------------------------------------------
# cleanup dangling folders
# ------------------------------------------------------------------------------
# some removals do not clean up after themselves
if [ ! -x /usr/bin/blueman-manager ];
then
    rm -rf /var/lib/blueman
fi

if [ ! -x /usr/bin/whoopsie ];
then
    rm -rf /var/lib/whoopsie
fi

# ------------------------------------------------------------------------------
# run autoremove to cleanout unneeded dependent packages
# ------------------------------------------------------------------------------
# 2016-05-04 rik: adding --purge so extra cruft from packages cleaned up
apt-get $YES --purge autoremove

echo
echo "*** Script Exit: app-removals.sh"
echo

exit 0
