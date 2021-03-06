#!/bin/bash
mkdir -p repos

GR="\033[32m"
RED="\033[91m"
RST="\033[0m"

function install_brew_if_needed() {
  if ! command -v brew > /dev/null; then
    echo "Brew not installed; installing"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
}

function install_node8_if_needed() {
  NODE_MAJOR_VERSION="none"
  if [ -f "/usr/local/opt/node@8/bin/node" ]; then
    NODE_VERSION=`/usr/local/opt/node@8/bin/node --version | tr -d "\n"`
    NODE_MAJOR_VERSION=`echo $NODE_VERSION | perl -pe 's/v([0-9]+).+/$1/'`
  fi
  
  if [ ! $NODE_MAJOR_VERSION == "8" ]; then
    echo -e "${RED}Node 8 not installed; installed node version: \"$NODE_MAJOR_VERSION\"$RST"
    echo -e "Installing Node 8 and setting up symlink"
    brew install node@8
  else
    echo -e "${GR}Node 8 installed$RST"
  fi
}

function assert_has_xcodebuild() {
  XCODE_VERSION="none"
  XCODE_MAJOR_VERSION="0"
  XCODE_MINOR_VERSION="0"
  if command -v xcodebuild > /dev/null; then
    XCODE_VERSION=`xcodebuild -version | grep Xcode | tr -d "\n" | perl -pe 's/Xcode //'`
    XCODE_MAJOR_VERSION=`echo $XCODE_VERSION | perl -pe 's/([0-9]+)\.[0-9]+/$1/'`
    XCODE_MINOR_VERSION=`echo $XCODE_VERSION | perl -pe 's/[0-9]+\.([0-9]+)/$1/'`
  fi
  
  #echo "XCODE Version: $XCODE_VERSION"
  #echo "XCODE Version: Major = $XCODE_MAJOR_VERSION, Minor = $XCODE_MINOR_VERSION"
  
  if [ $XCODE_MAJOR_VERSION > 10 ]; then
    echo -e "${GR}Xcode $XCODE_VERSION installed$RST"
  elif [ "$XCODE_VERSION" == "10.3" ]; then
    echo -e "${GR}Xcode 10.3 installed$RST"
  else
    echo -e "${RED}Xcode 10.3+ not installed$RST"
    echo -e "${RED}You need to install it and then rerun init.sh$RST"
    exit 1
  fi
}

rm pipe
mkfifo pipe

install_brew_if_needed

USBINFO=$( brew info usbmuxd | grep Cellar/libusbmuxd | cut -d\/ -f6 | cut -d\  -f1 | cut -d\. -f1,2 | cut -d\- -f1 )
if [ "$USBINFO" == "" ]; then
  brew install --HEAD usbmuxd
else
  if [ "$USBINFO" != "HEAD" ]; then
    brew uninstall usbmuxd --ignore-dependencies
    brew install --HEAD usbmuxd
  fi
fi

LIBIINFO=$( brew info libimobiledevice | grep Cellar/libimobiledevice | cut -d\/ -f6 | cut -d\  -f1 | cut -d\. -f1,2 | cut -d\- -f1 )
if [ "$LIBIINFO" == "" ]; then
  brew install --HEAD libimobiledevice
else
  if [ "$LIBIINFO" != "HEAD" ]; then
    brew uninstall libimobiledevice --ignore-dependencies
    brew install --HEAD libimobiledevice
  fi
fi

install_node8_if_needed
assert_has_xcodebuild

CACHE_FILE=$(brew --cache -s ./stf_ios_support.rb|tr -d "\n")
cp empty.tgz "${CACHE_FILE}"
HOMEBREW_NO_AUTO_UPDATE=1 brew install --build-from-source ./stf_ios_support.rb
