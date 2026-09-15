#!/bin/bash
# 安全试用：把 glass-ui 的新文件复制进 qml/pages/（全部是新文件名，不覆盖源码）。
# 用完后运行 restore-glass.sh 即可删掉，保持源码树干净。
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
DEST="$ROOT/qml/pages"

echo "[try-glass] copy new files -> $DEST"
cp -v "$HERE"/components/*.qml "$DEST"/
cp -v "$HERE"/theme/*.qml "$DEST"/
cp -v "$HERE"/pages/*.qml "$DEST"/

echo "[try-glass] strip '../components' imports (flattened dir auto-resolves)"
sed -i '/import "\.\.\/components"/d' "$DEST"/ConversationsGlassPage.qml "$DEST"/ChatGlassPage.qml "$DEST"/LoginGlassPage.qml "$DEST"/SettingsGlassPage.qml 2>/dev/null || \
sed -i '' '/import "\.\.\/components"/d' "$DEST"/ConversationsGlassPage.qml "$DEST"/ChatGlassPage.qml "$DEST"/LoginGlassPage.qml "$DEST"/SettingsGlassPage.qml

echo ""
echo "[try-glass] done. No source file was overwritten (all names are new: *Glass*.qml)."
echo "Preview options:"
echo "  A) Temporary preview: change qml/harbour-qqcat.qml initialPage to ConversationsGlassPage {}"
echo "     (or LoginGlassPage {}), rebuild, then 'git checkout -- qml/harbour-qqcat.qml' to revert."
echo "  B) In-app push: from any page, pageStack.push(Qt.resolvedUrl(\"ConversationsGlassPage.qml\"))"
echo ""
echo "To remove trial files: ./glass-ui/restore-glass.sh"
