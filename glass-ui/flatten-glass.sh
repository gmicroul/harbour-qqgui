#!/bin/bash
# usage: flatten-glass.sh <in.qml> <out.qml>
# Strip the source-tree-only `import "../components"` line: in the source
# tree glass pages live in glass-ui/pages, but installed they sit flat in
# qml/pages next to the components where same-dir lookup resolves them.
set -e
mkdir -p "$(dirname "$2")"
/bin/sed '/import "\.\.\/components"/d' "$1" > "$2"
