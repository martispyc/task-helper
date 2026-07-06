# Install/update the Task Pipeline into a project — one run does everything.
#
# Drop this repo folder into your project root, then run either of:
#   powershell -ExecutionPolicy Bypass -File task-helper\install.ps1    # from the project root
#   powershell -ExecutionPolicy Bypass -File install.ps1                # from inside the imported folder
#
# It removes this pipeline's old files (the four agent files, .github\task-helper\,
# the old root task-dashboard.html), puts every fresh file where it belongs,
# gitignores .github/task/, prints a quick tutorial, and finally deletes the
# imported repo folder itself so your project root stays clean.
#
# Flags:
#   -ResetTask       archive .github\task\context.md to .github\task\archive\ and start clean
#   -KeepSource      don't delete the imported repo folder after installing
#   -Shared <path>   make .github\task a junction into <path> — a OneDrive-synced
#                    SharePoint library folder — so the whole team's dashboards
#                    follow the same context.md (data stays inside your tenant)
param([switch]$ResetTask, [switch]$KeepSource, [string]$Shared)
$ErrorActionPreference = 'Stop'

$here = $PSScriptRoot
$src = Join-Path $here 'bundle'
if (-not (Test-Path (Join-Path $src '.github'))) { throw "bundle/ not found next to install.ps1" }

# Target = the project root. Running from inside the imported repo folder
# means the project root is its parent; anywhere else, it's where you are.
$target = (Get-Location).Path
if ($target -eq $here) { $target = Split-Path $here -Parent }
Set-Location $target
if (-not (Test-Path .git)) { Write-Warning "no .git in $target — make sure this is your project root" }
Write-Host "installing into: $target"

# ── clean out the old install (only OUR files — other teams' agents untouched)
foreach ($a in 'context-getter','planner','implementer','review') {
  $p = ".github\agents\$a.agent.md"
  if (Test-Path $p) { Remove-Item $p -Force }
}
Remove-Item .github\task-helper -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item task-dashboard.html -Force -ErrorAction SilentlyContinue

# ── put every file in place
New-Item -ItemType Directory -Force .github\agents, .github\task-helper | Out-Null
Copy-Item (Join-Path $src '.github\agents\*.agent.md') .github\agents\ -Force
Copy-Item (Join-Path $src '.github\task-helper\*.md')  .github\task-helper\ -Force
Copy-Item (Join-Path $src 'task-dashboard.html') . -Force

# ── task dir: local by default, or a junction into a synced shared folder
$taskDir = '.github\task'
if ($Shared) {
  if (-not (Test-Path $Shared -PathType Container)) {
    throw "shared folder not found: $Shared — sync the SharePoint library in OneDrive first, then pass its local path"
  }
  $sharedFull = (Resolve-Path $Shared).Path
  $item = Get-Item $taskDir -Force -ErrorAction SilentlyContinue
  if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    # already a junction — recreate it pointing at the requested target
    # (cmd rmdir removes only the junction, never the target's contents)
    cmd /c rmdir $taskDir
    New-Item -ItemType Junction -Path $taskDir -Target $sharedFull | Out-Null
    Write-Host "task folder linked to: $sharedFull"
  } else {
    if ($item) {
      # migrate local task data into the shared folder without clobbering
      Get-ChildItem $taskDir -Force | ForEach-Object {
        $dest = Join-Path $sharedFull $_.Name
        if (Test-Path $dest) {
          $arch = Join-Path $sharedFull 'archive'
          New-Item -ItemType Directory -Force $arch | Out-Null
          Move-Item $_.FullName (Join-Path $arch ("{0}-local-{1}" -f (Get-Date -Format 'yyyy-MM-dd-HHmm'), $_.Name)) -Force
          Write-Host ("shared folder already had {0} — local copy archived to archive\" -f $_.Name)
        } else {
          Move-Item $_.FullName $dest
        }
      }
      Remove-Item $taskDir -Force
    }
    New-Item -ItemType Junction -Path $taskDir -Target $sharedFull | Out-Null
    Write-Host "task folder shared: .github\task -> $sharedFull"
  }
} else {
  New-Item -ItemType Directory -Force $taskDir | Out-Null
}

if ($ResetTask -and (Test-Path .github\task\context.md)) {
  New-Item -ItemType Directory -Force .github\task\archive | Out-Null
  Move-Item .github\task\context.md (".github\task\archive\{0}-context.md" -f (Get-Date -Format 'yyyy-MM-dd-HHmm')) -Force
  Write-Host "task data archived to .github\task\archive\"
}

if (-not (Test-Path .gitignore) -or -not (Select-String -Path .gitignore -Pattern '^\.github/task/$' -Quiet)) {
  Add-Content .gitignore "`n.github/task/"
}
# a linked task dir can be a symlink on some setups — cover it without the slash too
if (-not (Select-String -Path .gitignore -Pattern '^\.github/task$' -Quiet)) {
  Add-Content .gitignore ".github/task"
}

# ── the imported repo folder has done its job — remove it
$sep = [IO.Path]::DirectorySeparatorChar
if ($KeepSource) {
  Write-Host "source folder kept: $here"
} elseif ($here.StartsWith("$target$sep", [StringComparison]::OrdinalIgnoreCase)) {
  Remove-Item $here -Recurse -Force
  Write-Host ("cleaned up: removed {0}\ (re-import this repo to update later)" -f (Split-Path $here -Leaf))
} else {
  Write-Host "source folder is outside the project — left in place: $here"
}

Write-Host @'

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
 install — task data is preserved. Add -ResetTask to archive it and
 start a fresh task.
──────────────────────────────────────────────────────────────────
'@

if ($Shared) {
  Write-Host @'
 Shared mode: .github\task points into your synced SharePoint library.
 Convention — agents run on ONE machine per task (the task owner's);
 everyone else opens task-dashboard.html against their own synced copy,
 which live-follows as OneDrive syncs it. Two machines running agents
 on the same task will produce OneDrive conflict copies.
──────────────────────────────────────────────────────────────────
'@
}
