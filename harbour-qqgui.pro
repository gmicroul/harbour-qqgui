QT += quick websockets network

CONFIG += c++11

# unsandboxed launches are dlopen'd by the mapplauncherd booster,
# which requires a position independent executable exporting main
QMAKE_CXXFLAGS += -fPIE
QMAKE_LFLAGS += -pie -rdynamic

TARGET = harbour-qqgui

SOURCES += \
    src/main_qqgui.cpp \
    src/onebotbridge.cpp \
    src/qrcodegen.cpp

HEADERS += \
    src/onebotbridge.h \
    src/qrcodegen.hpp

OTHER_FILES += \
    qml/harbour-qqgui.qml \
    qml/pages/*.qml \
    qml/cover/*.qml \
    qml/js/pinyin.js \
    glass-ui/pages/*.qml \
    glass-ui/components/*.qml \
    glass-ui/theme/*.qml \
    glass-ui/js/pinyin.js \
    harbour-qqgui.desktop \
    rpm/harbour-qqgui.spec

# ---- glass-ui flattening:
# glass pages live in glass-ui/pages and carry `import "../components"`.
# Installed they sit flat in qml/pages next to the components, where
# same-directory lookup resolves them, so no import line is needed
# (sources carry no `import "../components"` line at all).
# NOTE: files are listed from $$PWD (they exist at qmake time, so the
# install rules are generated); build-dir copies via QMAKE_EXTRA_COMPILERS
# are intentionally NOT used -- qmake silently drops INSTALLS entries
# whose files don't exist yet (that's what broke bin + glasspages before).
GLASS_PAGES = ConversationsGlassPage.qml \
              ChatGlassPage.qml \
              LoginGlassPage.qml \
              SettingsGlassPage.qml \
              InfoGlassPage.qml


# Installation (paths parallel harbour-qqcat, co-installable)
# NOTE: binary uses the canonical `target.path` (not bin.files =
# $$OUT_PWD/...) so the install rule always exists.
target.path = /usr/bin

qmlmain.path = /usr/share/harbour-qqgui/qml
qmlmain.files = qml/harbour-qqgui.qml

# shared original pages (tiles, viewer, attachment, info, emoji, ...)
qmlpages.path = /usr/share/harbour-qqgui/qml/pages
qmlpages.files = qml/pages/*.qml

# glass pages (installed flat next to components; the source-only
# `import "../components"` line is stripped post-copy; `../js/...`
# stays valid: pages/../js == qml/js)
glasspages.path = /usr/share/harbour-qqgui/qml/pages
glasspages.files = $$PWD/glass-ui/pages/ConversationsGlassPage.qml \
                   $$PWD/glass-ui/pages/ChatGlassPage.qml \
                   $$PWD/glass-ui/pages/LoginGlassPage.qml \
                   $$PWD/glass-ui/pages/SettingsGlassPage.qml \
                   $$PWD/glass-ui/pages/InfoGlassPage.qml

# glass components + theme (no processing needed, same flat dir)
glasscomp.path = /usr/share/harbour-qqgui/qml/pages
glasscomp.files = glass-ui/components/*.qml glass-ui/theme/*.qml

qmlcover.path = /usr/share/harbour-qqgui/qml/cover
qmlcover.files = qml/cover/*.qml

qmlimages.path = /usr/share/harbour-qqgui/qml/images
qmlimages.files = qml/images/*.png

qmljs.path = /usr/share/harbour-qqgui/qml/js
qmljs.files = qml/js/pinyin.js

desktop.path = /usr/share/applications
desktop.files = harbour-qqgui.desktop

icon86.path = /usr/share/icons/hicolor/86x86/apps
icon86.files = icons/86x86/harbour-qqgui.png

INSTALLS += target qmlmain qmlpages glasspages glasscomp qmlcover qmlimages qmljs desktop icon86
