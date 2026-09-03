Name:       harbour-qqcat
Summary:    OneBot11 QQ client for Sailfish OS
Version:    1.0.0
Release:    30
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
mkdir -p %{buildroot}%{_datarootdir}/harbour-qqcat/qml/components
install -m 644 qml/harbour-qqcat.qml      %{buildroot}%{_datarootdir}/harbour-qqcat/qml/
for f in qml/pages/*.qml; do install -m 644 "$f" %{buildroot}%{_datarootdir}/harbour-qqcat/qml/pages/; done
for f in qml/cover/*.qml; do install -m 644 "$f" %{buildroot}%{_datarootdir}/harbour-qqcat/qml/cover/; done
for f in qml/images/*.png; do install -m 644 "$f" %{buildroot}%{_datarootdir}/harbour-qqcat/qml/images/; done
if [ -f qml/js/pinyin.js ]; then install -m 644 qml/js/pinyin.js %{buildroot}%{_datarootdir}/harbour-qqcat/qml/js/pinyin.js; fi
for f in qml/components/*.qml; do install -m 644 "$f" %{buildroot}%{_datarootdir}/harbour-qqcat/qml/components/; done

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
* Thu Sep 4 2026 qqbridge contributors 1.0.0-30
- Chat header 78→84, remove clip, anchor title top 14 to prevent group ID pushing title up

* Thu Sep 4 2026 qqbridge contributors 1.0.0-29
- Chat header 72→78 clip true, title width page.width-210→Column width, font Medium→Small, add elide to prevent top overflow

* Thu Sep 4 2026 qqbridge contributors 1.0.0-28
- Show own avatar in sent bubbles (previously hid for mine)

* Thu Sep 4 2026 qqbridge contributors 1.0.0-27
- Show real QQ avatars: Conversations, Chat header, sender bubbles, ContactPicker via q.qlogo.cn

* Thu Sep 4 2026 qqbridge contributors 1.0.0-26
- Revert preview to y38 pressed look (worse when below name)
- Fix sendButton MouseArea doSend scope → sendButton.doSend()

* Thu Sep 4 2026 qqbridge contributors 1.0.0-25
- Conversations preview: anchor below nameLabel instead of fixed y38 to avoid overlap

* Thu Sep 4 2026 qqbridge contributors 1.0.0-24
- Bubble menu: full-width glass, distributed spacing to prevent stacking

* Thu Sep 4 2026 qqbridge contributors 1.0.0-23
- Fix bubble menu stacking: keep Reply/@ always in layout via opacity/enabled instead of visible

* Thu Sep 4 2026 qqbridge contributors 1.0.0-22
- Chat bubble menu: 44→48 height, spacing 10→12, wider buttons to avoid stacking

* Thu Sep 4 2026 qqbridge contributors 1.0.0-21
- Conversations 56→64 icon28→32 more opaque to fix perceived small size (glass faintness)

* Thu Sep 4 2026 qqbridge contributors 1.0.0-20
- Enlarge both pages refresh/settings to 56 (previously both shrank to 52)

* Thu Sep 4 2026 qqbridge contributors 1.0.0-19
- Sync first page refresh/settings 56→52 to match second page header (52)

* Thu Sep 4 2026 qqbridge contributors 1.0.0-18
- First page 52→56, second page header 36→52 (answer sizing question)

* Thu Sep 4 2026 qqbridge contributors 1.0.0-17
- Remove duplicate status row (two QQ numbers under title)

* Thu Sep 4 2026 qqbridge contributors 1.0.0-16
- Fix title挤右：还原 Sailfish 左置标题+右置按钮布局（玻璃底保留）

* Thu Sep 4 2026 qqbridge contributors 1.0.0-15
- Fix Conversations title挤在右边：PageHeader anchors.left/right分离，按钮 Row 锚右

* Thu Sep 4 2026 qqbridge contributors 1.0.0-14
- Conversations top bar: switch to Sailfish native PageHeader+IconButton (glass only as background)

* Thu Sep 4 2026 qqbridge contributors 1.0.0-13
- Conversations top bar: enlarge refresh/settings 38→52, icon 22→26, spacing Medium

* Thu Sep 4 2026 qqbridge contributors 1.0.0-12
- Enlarge emoji 38→52, menu buttons 32→44, fix Conversations icon separation (Rectangle+Image)

* Thu Sep 4 2026 qqbridge contributors 1.0.0-11
- Rebuild ChatPage from original: restore bubble delegate, fix input Row with TextArea background glass + correct auto-grow

* Thu Sep 4 2026 qqbridge contributors 1.0.0-10
- Revert messages/input font to Small as first version
- Fix input auto-grow: use contentHeight + wrapMode TextEdit.WrapAtWordBoundaryOrAnywhere

* Thu Sep 4 2026 qqbridge contributors 1.0.0-9
- Fix input auto-grow: use content-driven height + Text.WrapAtWordBoundaryOrAnywhere

* Thu Sep 4 2026 qqbridge contributors 1.0.0-8
- Fix input box: remove anchors.fill loop, use centered TextArea +12, eliminate half-empty lower area

* Thu Sep 4 2026 qqbridge contributors 1.0.0-7
- Enlarge emoji/+ buttons 38→52 and send 42→64, add lineHeight 1.55 fix text clipping

* Thu Sep 4 2026 qqbridge contributors 1.0.0-6
- Enlarge chat message font from Small to Medium (readability)
- Enlarge input field font to Medium

* Thu Sep 4 2026 qqbridge contributors 1.0.0-5
- Fix Conversations filter pills not clickable (implicitWidth + Item wrapper)
- Fix search field alignment (restore Sailfish SearchField inside glass)
- Fix chat bubble layout: remove body/bubble binding loop, restore text-wrap and Flow wrapping

* Thu Sep 4 2026 qqbridge contributors 1.0.0-4
- Glassmorphism UI overhaul: frosted glass, gradient blobs, translucent cards
- Conversations, Chat, Login, Settings, Attachment, Cover all restyled
- New qml/components (GlassBackground/Card/Section)

* Tue Sep 2 2026 qqbridge contributors 1.0.0-3
- Fix group-chat quoted text not displaying (use inline reply segment text)
- Fix self-sent reply bubble width collapsing (break binding loop)
- Fix quoted text + image coexisting in quote block

* Sun Aug 30 2026 qqbridge contributors 1.0.0-2
- Fix group-chat reply/quote button vanishing on large message ids
- Correct "@member" visibility for own messages
- Group file upload tiles + remote file download support

* Mon Aug 25 2026 qqbridge contributors 1.0.0-1
- Initial OpenRepos release
- QR login, conversation list, group/private chat
- Image / video / file support, native QQ emoji
- Settings: remote NapCat connection configuration
