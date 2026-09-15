#!/bin/bash
# 清理 try-glass.sh 复制进去的试用文件（源码自带文件不受影响）。
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
DEST="$ROOT/qml/pages"

rm -fv "$DEST"/GlassBackground.qml "$DEST"/GlassCard.qml "$DEST"/GlassAvatar.qml \
       "$DEST"/GlassBadge.qml "$DEST"/GlassTabBar.qml "$DEST"/GlassChatBubble.qml \
       "$DEST"/GlassSectionTitle.qml "$DEST"/GlassTheme.qml \
       "$DEST"/ConversationsGlassPage.qml "$DEST"/ChatGlassPage.qml \
       "$DEST"/LoginGlassPage.qml "$DEST"/SettingsGlassPage.qml

echo "[restore-glass] done. Check with: git status --porcelain"
