#!/usr/bin/env bash
# Symlink every skill in skills/ into ~/.claude/skills/ so Claude Code loads it in all projects.
# Safe to re-run: existing correct links are left alone, and nothing is ever overwritten.
# Project-only skills are never linked: install them per project with `npx skills add`.
set -euo pipefail

project_only=" batch "

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
mkdir -p "$dest"

for dir in "$repo"/skills/*/; do
  dir="${dir%/}"
  name="$(basename "$dir")"
  link="$dest/$name"

  if [ ! -f "$dir/SKILL.md" ]; then
    echo "skip  $name (no SKILL.md)"
  elif [[ "$project_only" == *" $name "* ]]; then
    if [ -L "$link" ] && [ "$(readlink "$link")" = "$dir" ]; then
      echo "warn  $name is project-only but linked at $link; remove that link"
    else
      echo "skip  $name (project-only: npx skills add sirateck/skills@$name)"
    fi
  elif [ -L "$link" ] && [ "$(readlink "$link")" = "$dir" ]; then
    echo "ok    $name"
  elif [ -e "$link" ] || [ -L "$link" ]; then
    echo "skip  $name ($link already exists; remove it first to link this one)"
  else
    ln -s "$dir" "$link"
    echo "link  $name -> $dir"
  fi
done
