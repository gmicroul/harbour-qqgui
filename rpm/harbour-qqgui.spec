Name:       harbour-qqgui
Summary:    Glass UI QQ client for Sailfish OS (OneBot11)
Version:    1.0.0
Release:    2
License:    MIT
URL:        https://openrepos.net/content/qqbridge
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfish-version >= 3.0
BuildArch:  aarch64

%description
QQ Glass — glassmorphism UI variant of the QQ Bridge client for Sailfish OS.
Connects to a NapCat instance via OneBot11 protocol (WebSocket + HTTP).

Same bridge, same protocol, new frosted-glass look:
- Glass conversation list (Theme-scaled rows, round avatars, pill filters)
- Glass chat bubbles with outside avatars and quote strips
- Glass login card and grouped glass settings pages
- Shared tiles reused as-is: image viewer, attachments, emoji, faces

Co-installable with harbour-qqcat (separate binary, QML and desktop entry).
Requires a running NapCat instance with OneBot11 WebSocket and HTTP API.
Configure connection in Settings page after first launch.

%prep
%setup -q -n %{name}-%{version}

%build
qmake harbour-qqgui.pro CONFIG+=release PREFIX=%{_prefix}
make %{?jobs:-j%{jobs}}

%install
rm -rf %{buildroot}
make install INSTALL_ROOT=%{buildroot}

# desktop
install -Dm 644 harbour-qqgui.desktop \
    %{buildroot}%{_datarootdir}/applications/harbour-qqgui.desktop

# icon
install -Dm 644 icons/86x86/harbour-qqgui.png \
    %{buildroot}%{_datarootdir}/icons/hicolor/86x86/apps/harbour-qqgui.png

%files
%defattr(-,root,root,-)
%license LICENSE
%attr(755,root,root) %{_bindir}/harbour-qqgui
%dir %{_datarootdir}/harbour-qqgui/
%{_datarootdir}/harbour-qqgui/qml/
%{_datarootdir}/applications/harbour-qqgui.desktop
%{_datarootdir}/icons/hicolor/86x86/apps/harbour-qqgui.png

%changelog
* Tue Sep 15 2026 qqbridge contributors 1.0.0-2
- Theme-scale UI (no bare px), S3-wrapped launcher icon, glass cover, InfoGlassPage, emoji panel, @-mention menu
* Tue Sep 15 2026 qqbridge contributors 1.0.0-1
- New package harbour-qqgui: glassmorphism UI variant, co-installable with qqcat
- Glass pages installed flat into qml/pages (same-dir resolution, no source changes)
- Shared tiles/viewer/attachment/emoji reused from qml/pages
