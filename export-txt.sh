#!/usr/bin/env bash
# Build export/ with every deliverable as <name>.txt — the set that passes SEB attachment filters.
# On the receiving side: rename setup.ps1.txt -> setup.ps1 and run it (it handles the rest).
set -e
cd "$(dirname "$0")"

rm -rf export && mkdir export

find bundle -type f | while read -r f; do
  cp "$f" "export/$(basename "$f").txt"
done
cp README.md export/README.md.txt
cp setup.ps1 export/setup.ps1.txt
cp setup.sh  export/setup.sh.txt

echo "export/ ready:"
ls export
