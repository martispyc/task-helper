# Task Pipeline setup — run from the repo root with the transferred *.txt files present.
# First rename setup.ps1.txt -> setup.ps1 by hand, then:
#   powershell -ExecutionPolicy Bypass -File setup.ps1

$ErrorActionPreference = 'Stop'

$agents  = 'context-getter.agent.md','planner.agent.md','implementer.agent.md','review.agent.md'
$support = 'context-template.md','framework-rules.md','context-example.md','team-template.md'

New-Item -ItemType Directory -Force .github\agents, .github\task-helper, .github\task | Out-Null

# strip the .txt transfer suffix (setup files excluded)
Get-ChildItem -File *.txt |
  Where-Object { $_.Name -match '\.(md|html|sh)\.txt$' } |
  ForEach-Object { Rename-Item $_ ($_.Name -replace '\.txt$','') -Force }

foreach ($f in $agents)  { if (Test-Path $f) { Move-Item $f ".github\agents\$f"      -Force } }
foreach ($f in $support) { if (Test-Path $f) { Move-Item $f ".github\task-helper\$f" -Force } }
# task-dashboard.html and README.md stay in the repo root

# workspace layout: per-ticket folders + shared team context
New-Item -ItemType Directory -Force .github\task\tasks | Out-Null
if (-not (Test-Path .github\task\team.md) -and (Test-Path .github\task-helper\team-template.md)) {
  Copy-Item .github\task-helper\team-template.md .github\task\team.md
}

if (-not (Test-Path .gitignore) -or -not (Select-String -Path .gitignore -Pattern '^\.github/task/' -Quiet)) {
  Add-Content .gitignore "`n.github/task/"
}
if (-not (Select-String -Path .gitignore -Pattern '^\.github/task$' -Quiet)) {
  Add-Content .gitignore ".github/task"
}

# the transfer set has done its job — remove the setup scripts themselves
foreach ($f in 'setup.sh','setup.sh.txt','setup.ps1','setup.ps1.txt') {
  if (Test-Path $f) { Remove-Item $f -Force }
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

 (Admins: enable the Claude Opus 4.8 model policy in Copilot settings.)
──────────────────────────────────────────────────────────────────
'@
