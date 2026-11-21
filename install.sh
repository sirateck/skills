#!/usr/bin/env bash
# Symlink every skill in skills/ into ~/.claude/skills/ so Claude Code loads it in all projects.
# Safe to re-run: existing correct links are left alone, and nothing is ever overwritten.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
mkdir -p "$dest"

for dir in "$repo"/skills/*/; do
  dir="${dir%/}"
  name="$(basename "$dir")"
  link="$dest/$name"

  if [ ! -f "$dir/SKILL.md" ]; then
    echo "skip  $name (no SKILL.md)"
  elif [ -L "$link" ] && [ "$(readlink "$link")" = "$dir" ]; then
    echo "ok    $name"
  elif [ -e "$link" ] || [ -L "$link" ]; then
    echo "skip  $name ($link already exists; remove it first to link this one)"
  else
    ln -s "$dir" "$link"
    echo "link  $name -> $dir"
  fi
done
