#!/usr/bin/env bash
# Installs tracked hooks from scripts/hooks/ into .git/hooks/.
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$repo_root" ]; then
	echo "ERROR: not in a git repository. Run from within the pantry_app repo."
	exit 1
fi

src="$repo_root/scripts/hooks"
dst="$repo_root/.git/hooks"

if [ ! -d "$src" ]; then
	echo "ERROR: $src not found."
	exit 1
fi

installed=0
backed_up=0

for hook in "$src"/*; do
	name=$(basename "$hook")
	[ "$name" = ".gitkeep" ] && continue
	[ -f "$hook" ] || continue

	target="$dst/$name"

	if [ -f "$target" ] && ! diff -q "$hook" "$target" &>/dev/null; then
		cp "$target" "${target}.bak.$(date +%s)"
		echo "  BACKED UP existing $name -> ${name}.bak.*"
		((backed_up++))
	fi

	cp "$hook" "$target"
	chmod +x "$target"
	echo "  INSTALLED $name hook"
	((installed++))
done

echo ""
echo "Done. $installed hook(s) installed, $backed_up existing hook(s) backed up."
echo "The stale-info check will now run on every 'git push'."
echo "Use 'git push --no-verify' to bypass."
