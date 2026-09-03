#!/bin/bash
# DEV quick-deploy for harbour-qqcat (builds into /usr/local/bin).
set -e
cd "$(dirname "$0")"

qmake
make -j4 >/dev/null

sudo -n install -m 755 harbour-qqcat /usr/local/bin/harbour-qqcat
sudo -n install -m 755 harbour-qqcat /usr/bin/harbour-qqcat

sudo -n mkdir -p /usr/share/harbour-qqcat/qml/pages /usr/share/harbour-qqcat/qml/cover /usr/share/harbour-qqcat/qml/images
sudo -n cp qml/harbour-qqcat.qml /usr/share/harbour-qqcat/qml/
sudo -n cp qml/pages/*.qml /usr/share/harbour-qqcat/qml/pages/
sudo -n cp qml/cover/*.qml /usr/share/harbour-qqcat/qml/cover/
sudo -n mkdir -p /usr/share/harbour-qqcat/qml/js
sudo -n cp qml/js/*.js /usr/share/harbour-qqcat/qml/js/
sudo -n chmod 755 /usr/share/harbour-qqcat/qml/js
sudo -n chmod 644 /usr/share/harbour-qqcat/qml/js/*.js
sudo -n cp qml/images/*.png /usr/share/harbour-qqcat/qml/images/
sudo -n chmod 755 /usr/share/harbour-qqcat/qml /usr/share/harbour-qqcat/qml/pages /usr/share/harbour-qqcat/qml/cover /usr/share/harbour-qqcat/qml/images
sudo -n chmod 644 /usr/share/harbour-qqcat/qml/*.qml /usr/share/harbour-qqcat/qml/pages/*.qml \
                  /usr/share/harbour-qqcat/qml/cover/*.qml /usr/share/harbour-qqcat/qml/images/*.png
sudo -n install -m 644 harbour-qqcat.desktop /usr/share/applications/harbour-qqcat.desktop

echo "installed (dev mode). launch: /usr/bin/harbour-qqcat"
