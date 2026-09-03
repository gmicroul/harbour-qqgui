QT += quick websockets network

CONFIG += c++11

# unsandboxed launches are dlopen'd by the mapplauncherd booster,
# which requires a position independent executable exporting main
QMAKE_CXXFLAGS += -fPIE
QMAKE_LFLAGS += -pie -rdynamic

TARGET = harbour-qqcat

SOURCES += \
    src/main.cpp \
    src/onebotbridge.cpp \
    src/qrcodegen.cpp

HEADERS += \
    src/onebotbridge.h \
    src/qrcodegen.hpp

OTHER_FILES += \
    qml/harbour-qqcat.qml \
    qml/pages/LoginPage.qml \
    qml/pages/ConversationsPage.qml \
    qml/pages/ChatPage.qml \
    qml/pages/ContactPickerPage.qml \
    qml/pages/ImageTile.qml \
    qml/pages/ImageViewerPage.qml \
    qml/pages/SettingsPage.qml \
    qml/pages/InfoPage.qml \
    qml/pages/InfoBlock.qml \
    qml/pages/AttachmentPage.qml \
    qml/pages/EmojiPanel.qml \
    qml/pages/VideoTile.qml \
    qml/pages/FileTile.qml \
    qml/pages/FaceTile.qml \
    harbour-qqcat.desktop \
    qml/js/pinyin.js \
    rpm/harbour-qqcat.spec


# Installation
bin.path = /usr/bin
bin.files = harbour-qqcat

qmlmain.path = /usr/share/harbour-qqcat/qml
qmlmain.files = qml/harbour-qqcat.qml

qmlpages.path = /usr/share/harbour-qqcat/qml/pages
qmlpages.files = qml/pages/*.qml

qmlcover.path = /usr/share/harbour-qqcat/qml/cover
qmlcover.files = qml/cover/*.qml

qmlimages.path = /usr/share/harbour-qqcat/qml/images
qmlimages.files = qml/images/*.png

qmljs.path = /usr/share/harbour-qqcat/qml/js
qmljs.files = qml/js/pinyin.js

desktop.path = /usr/share/applications
desktop.files = harbour-qqcat.desktop

icon86.path = /usr/share/icons/hicolor/86x86/apps
icon86.files = icons/86x86/harbour-qqcat.png

INSTALLS += bin qmlmain qmlpages qmlcover qmlimages qmljs desktop icon86
