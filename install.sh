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
#   --reset-task      archive .github/task/context.md to .github/task/archive/ and start clean
#   --keep-source     don't delete the imported repo folder after installing
#   --shared <path>   make .github/task a link into <path> — a OneDrive-synced
#                     SharePoint library folder — so the whole team's dashboards
#                     follow the same context.md (data stays inside your tenant)
set -e

main() {
  local RESET_TASK=0 KEEP_SOURCE=0 SHARED=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --reset-task)  RESET_TASK=1 ;;
      --keep-source) KEEP_SOURCE=1 ;;
      --shared)      shift; SHARED="${1:-}"
                     [ -n "$SHARED" ] || { echo "error: --shared needs a path (the OneDrive-synced library folder)"; exit 1; } ;;
      --shared=*)    SHARED="${1#--shared=}" ;;
      *) echo "unknown flag: $1 (known: --reset-task, --keep-source, --shared <path>)"; exit 1 ;;
    esac
    shift
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
  mkdir -p .github/agents .github/task-helper
  cp "$SRC"/.github/agents/*.agent.md .github/agents/
  cp "$SRC"/.github/task-helper/*.md  .github/task-helper/
  cp "$SRC"/task-dashboard.html .

  # ── task dir: local by default, or a link into a synced shared folder
  if [ -n "$SHARED" ]; then
    SHARED="$(cd "$SHARED" 2>/dev/null && pwd -P)" \
      || { echo "error: shared folder not found — sync the SharePoint library in OneDrive first, then pass its local path"; exit 1; }
    if [ -L .github/task ]; then
      if [ "$(cd .github/task && pwd -P)" = "$SHARED" ]; then
        echo "shared task folder already linked: $SHARED"
      else
        rm .github/task && ln -s "$SHARED" .github/task
        echo "task folder re-linked to: $SHARED"
      fi
    else
      if [ -d .github/task ]; then
        # migrate local task data into the shared folder without clobbering
        local f base
        for f in .github/task/* .github/task/.[!.]*; do
          [ -e "$f" ] || continue
          base="$(basename "$f")"
          if [ -e "$SHARED/$base" ]; then
            mkdir -p "$SHARED/archive"
            mv "$f" "$SHARED/archive/$(date +%F-%H%M)-local-$base"
            echo "shared folder already had $base — local copy archived to archive/"
          else
            mv "$f" "$SHARED/"
          fi
        done
        rmdir .github/task
      fi
      ln -s "$SHARED" .github/task
      echo "task folder shared: .github/task -> $SHARED"
    fi
  else
    mkdir -p .github/task
  fi

  # ── workspace layout: per-ticket folders + shared team context
  mkdir -p .github/task/tasks
  [ -f .github/task/team.md ] || cp "$SRC/.github/task-helper/team-template.md" .github/task/team.md

  # migrate a v1 single-task layout into its own ticket folder
  if [ -f .github/task/context.md ]; then
    local KEY
    KEY="$(grep -m1 '^# ' .github/task/context.md | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | head -1 || true)"
    [ -n "$KEY" ] || KEY="migrated"
    mkdir -p ".github/task/tasks/$KEY"
    if [ -e ".github/task/tasks/$KEY/context.md" ]; then
      mv .github/task/context.md ".github/task/tasks/$KEY/$(date +%F-%H%M)-context.md"
    else
      mv .github/task/context.md ".github/task/tasks/$KEY/context.md"
    fi
    echo "migrated old context.md -> tasks/$KEY/"
  fi

  if [ "$RESET_TASK" = 1 ] && [ -n "$(ls -A .github/task/tasks 2>/dev/null)" ]; then
    mkdir -p .github/task/archive
    mv .github/task/tasks ".github/task/archive/$(date +%F-%H%M)-tasks"
    mkdir -p .github/task/tasks
    echo "all ticket contexts archived to .github/task/archive/"
  fi

  grep -qx '.github/task/' .gitignore 2>/dev/null || printf '\n.github/task/\n' >> .gitignore
  # a linked task dir is a symlink — the trailing-slash pattern doesn't cover it
  grep -qx '.github/task' .gitignore 2>/dev/null || printf '.github/task\n' >> .gitignore

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
 3. Tell it the ticket key (e.g. KIDS-1428) and paste the ticket.
    Feed it chats/docs and relay its colleague questions until it
    says:  context 100/100 ✅ READY FOR PLANNING
 4. Switch agent → "Planner"      — writes the step plan under ## Planning.
 5. Switch agent → "Implementer"  — executes the steps one at a time.
 6. Switch agent → "Review"       — runs type check/build/tests itself,
    then appends an APPROVED / REJECTED verdict.
 7. Watch it live: open task-dashboard.html in Edge/Chrome and point it
    at your .github/task folder — a ticket switcher shows every task
    (or click "view with sample data" first).

 Every ticket lives in .github/task/tasks/<KEY>/context.md; team.md in
 the same folder is the shared context every agent reads on every
 ticket. All of it is gitignored — internal text never leaves the
 machine (or your tenant, in shared mode).

 Updating later: import this repo into the project root again and re-run
 install — task data is preserved. Add --reset-task to archive all
 ticket contexts and start clean.
──────────────────────────────────────────────────────────────────
TUTORIAL

  if [ -n "$SHARED" ]; then
    cat <<'SHAREDNOTE'
 Shared mode: .github/task points into your synced SharePoint library —
 every ticket folder and team.md are shared with the team, and
 SharePoint keeps automatic version history of each save.
 Convention — agents run on ONE machine per ticket (its owner's);
 everyone else opens the dashboard on their own synced copy, which
 live-follows as OneDrive syncs. Two machines running agents on the
 same ticket will produce OneDrive conflict copies.
──────────────────────────────────────────────────────────────────
SHAREDNOTE
  fi
}

main "$@"; exit
