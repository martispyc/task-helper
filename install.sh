#!/usr/bin/env bash
# Install/update the Task Pipeline into a project — one run does everything.
#
# Drop this repo folder into your project root, then run either of:
#   bash task-helper/install.sh        # from the project root
#   bash install.sh                    # from inside the imported folder
#
# It removes this pipeline's old files (the four agent files, .github/task-helper/,
# the old root task-dashboard.html), puts every fresh file where it belongs,
# gitignores .github/task/, prints a quick tutorial, and finally deletes the
# imported repo folder itself so your project root stays clean.
#
# Flags:
#   --reset-task    archive .github/task/context.md to .github/task/archive/ and start clean
#   --keep-source   don't delete the imported repo folder after installing
set -e

main() {
  local RESET_TASK=0 KEEP_SOURCE=0 arg
  for arg in "$@"; do
    case "$arg" in
      --reset-task)  RESET_TASK=1 ;;
      --keep-source) KEEP_SOURCE=1 ;;
      *) echo "unknown flag: $arg (known: --reset-task, --keep-source)"; exit 1 ;;
    esac
  done

  local HERE SRC TARGET
  HERE="$(cd "$(dirname "$0")" && pwd)"
  SRC="$HERE/bundle"
  [ -d "$SRC/.github" ] || { echo "error: bundle/ not found next to install.sh"; exit 1; }

  # Target = the project root. Running from inside the imported repo folder
  # means the project root is its parent; anywhere else, it's where you are.
  if [ "$(pwd)" = "$HERE" ]; then TARGET="$(dirname "$HERE")"; else TARGET="$(pwd)"; fi
  cd "$TARGET"
  [ -d .git ] || echo "warning: no .git in $TARGET — make sure this is your project root"
  echo "installing into: $TARGET"

  # ── clean out the old install (only OUR files — other teams' agents untouched)
  local a
  for a in context-getter planner implementer review; do
    rm -f ".github/agents/$a.agent.md"
  done
  rm -rf .github/task-helper
  rm -f task-dashboard.html

  # ── put every file in place
  mkdir -p .github/agents .github/task-helper .github/task
  cp "$SRC"/.github/agents/*.agent.md .github/agents/
  cp "$SRC"/.github/task-helper/*.md  .github/task-helper/
  cp "$SRC"/task-dashboard.html .

  if [ "$RESET_TASK" = 1 ] && [ -f .github/task/context.md ]; then
    mkdir -p .github/task/archive
    mv .github/task/context.md ".github/task/archive/$(date +%F-%H%M)-context.md"
    echo "task data archived to .github/task/archive/"
  fi

  grep -qx '.github/task/' .gitignore 2>/dev/null || printf '\n.github/task/\n' >> .gitignore

  # ── the imported repo folder has done its job — remove it
  if [ "$KEEP_SOURCE" = 1 ]; then
    echo "source folder kept: $HERE"
  else
    case "$HERE" in
      "$TARGET"/*)
        rm -rf "$HERE"
        echo "cleaned up: removed $(basename "$HERE")/ (re-import this repo to update later)"
        ;;
      *)
        echo "source folder is outside the project — left in place: $HERE"
        ;;
    esac
  fi

  cat <<'TUTORIAL'

Task Pipeline installed ✅

── Quick tutorial ────────────────────────────────────────────────
 1. Reload VS Code  (Ctrl+Shift+P → "Developer: Reload Window").
 2. Open Copilot Chat → agent picker → "Context Getter".
 3. Paste your Jira ticket. Feed it chats/docs and relay its
    colleague questions until it says:  context 100/100 ✅ READY FOR PLANNING
 4. Switch agent → "Planner"      — writes the step plan under ## Planning.
 5. Switch agent → "Implementer"  — executes the steps one at a time.
 6. Switch agent → "Review"       — runs type check/build/tests itself,
    then appends an APPROVED / REJECTED verdict.
 7. Watch it live: open task-dashboard.html in Edge/Chrome and point it
    at .github/task/context.md (or click "view with sample data" first).

 Everything the agents know lives in .github/task/context.md (gitignored —
 it may hold internal ticket text, so it never leaves your machine).

 Updating later: import this repo into the project root again and re-run
 install — task data is preserved. Add --reset-task to archive it and
 start a fresh task.
──────────────────────────────────────────────────────────────────
TUTORIAL
}

main "$@"; exit
