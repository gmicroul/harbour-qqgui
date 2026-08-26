Name:       harbour-qqcat
Summary:    OneBot11 QQ client for Sailfish OS
Version:    1.0.0
Release:    1
License:    MIT
URL:        https://openrepos.net/content/qqbridge
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfish-version >= 3.0
BuildArch:  aarch64

%description
QQ Bridge client for Sailfish OS.
Connects to a NapCat instance via OneBot11 protocol (WebSocket + HTTP).

Features:
- QR code login with auto-refresh
- Conversation list with unread badges and search
- Group chat / private chat with history replay
- Image thumbnails with full-screen viewer
- Video and file download support
- QQ native emoji rendering (200+ faces)
- Unicode emoji picker panel
- Reply-to-message with official quote format
- @mention group members, copy message text
- Message notifications (banner + sound)
- Settings page: remote NapCat connection support

Requires a running NapCat instance with OneBot11 WebSocket and HTTP API.
Configure connection in Settings page after first launch.

%prep
%setup -q -n %{name}-%{version}

%build
qmake CONFIG+=release PREFIX=%{_prefix}
make %{?jobs:-j%{jobs}}

%install
rm -rf %{buildroot}

# binary
install -Dm 755 harbour-qqcat %{buildroot}%{_bindir}/harbour-qqcat

# QML main + pages + cover + images + js
mkdir -p %{buildroot}%{_datarootdir}/harbour-qqcat/qml/pages
mkdir -p %{buildroot}%{_datarootdir}/harbour-qqcat/qml/cover
mkdir -p %{buildroot}%{_datarootdir}/harbour-qqcat/qml/images
mkdir -p %{buildroot}%{_datarootdir}/harbour-qqcat/qml/js
install -m 644 qml/harbour-qqcat.qml      %{buildroot}%{_datarootdir}/harbour-qqcat/qml/
for f in qml/pages/*.qml; do install -m 644 "$f" %{buildroot}%{_datarootdir}/harbour-qqcat/qml/pages/; done
for f in qml/cover/*.qml; do install -m 644 "$f" %{buildroot}%{_datarootdir}/harbour-qqcat/qml/cover/; done
for f in qml/images/*.png; do install -m 644 "$f" %{buildroot}%{_datarootdir}/harbour-qqcat/qml/images/; done
if [ -f qml/js/pinyin.js ]; then install -m 644 qml/js/pinyin.js %{buildroot}%{_datarootdir}/harbour-qqcat/qml/js/pinyin.js; fi

# desktop
install -Dm 644 harbour-qqcat.desktop \
    %{buildroot}%{_datarootdir}/applications/harbour-qqcat.desktop

# icon
install -Dm 644 icons/86x86/harbour-qqcat.png \
    %{buildroot}%{_datarootdir}/icons/hicolor/86x86/apps/harbour-qqcat.png

%files
%defattr(-,root,root,-)
%license LICENSE
%attr(755,root,root) %{_bindir}/harbour-qqcat
%dir %{_datarootdir}/harbour-qqcat/
%{_datarootdir}/harbour-qqcat/qml/
%{_datarootdir}/applications/harbour-qqcat.desktop
%{_datarootdir}/icons/hicolor/86x86/apps/harbour-qqcat.png

%changelog
* Mon Aug 25 2026 qqbridge contributors 1.0.0-1
- Initial OpenRepos release
- QR login, conversation list, group/private chat
- Image / video / file support, native QQ emoji
- Settings: remote NapCat connection configuration
