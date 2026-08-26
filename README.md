# harbour-qqcat

QQ Bridge client for Sailfish OS — connects to a NapCat instance via OneBot11 protocol.

## Features
- QR code login (60s auto-refresh + manual refresh)
- Conversation list with unread badges, search & filter tabs
- Group chat / private chat with full message history replay
- Image thumbnails with full-screen viewer
- Video save to device gallery
- File receive & download
- QQ native emoji rendering (200+ faces)
- Unicode emoji picker panel
- Reply-to-message with official quote format
- @mention group members
- Copy message text to clipboard
- Message notifications (banner + sound)
- Settings page: remote NapCat connection support, image/history preferences

## Architecture
```
harbour-qqcat (Sailfish app)
  ⇅ OneBot11 protocol (WebSocket events + HTTP actions)
NapCat (headless QQ client, container/PC/server)
  ⇅ QQ protocol
Tencent servers
```

## Requirements
- NapCat instance running somewhere accessible
- OneBot11 WebSocket + HTTP API enabled on NapCat
- Optional: access_token for authentication

## Build
```bash
qmake && make
./install.sh   # dev mode (installs to /usr/local/bin)
# or: rpmbuild -bb rpm/harbour-qqcat.spec
```

## License
MIT
