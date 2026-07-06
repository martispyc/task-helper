# Install/update the Task Pipeline into the CURRENT directory.
# Run from the TARGET PROJECT ROOT:
#   powershell -ExecutionPolicy Bypass -File \path\to\task-pipeline\install.ps1              # refresh tooling, keep task data
#   powershell -ExecutionPolicy Bypass -File \path\to\task-pipeline\install.ps1 -ResetTask   # also archive + clear .github\task\
param([switch]$ResetTask)
$ErrorActionPreference = 'Stop'

$src = Join-Path $PSScriptRoot 'bundle'
if (-not (Test-Path (Join-Path $src '.github'))) { throw "bundle/ not found next to install.ps1" }
if (-not (Test-Path .git)) { Write-Warning "no .git here — make sure you're in the target project root" }

New-Item -ItemType Directory -Force .github\agents, .github\task-helper, .github\task | Out-Null

# remove only OUR old files (other teams' agents untouched)
foreach ($a in 'context-getter','planner','implementer','review') {
  $p = ".github\agents\$a.agent.md"
  if (Test-Path $p) { Remove-Item $p -Force }
}
Remove-Item .github\task-helper -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force .github\task-helper | Out-Null

Copy-Item (Join-Path $src '.github\agents\*.agent.md') .github\agents\ -Force
Copy-Item (Join-Path $src '.github\task-helper\*.md')  .github\task-helper\ -Force
Copy-Item (Join-Path $src 'task-dashboard.html') . -Force

if ($ResetTask -and (Test-Path .github\task\context.md)) {
  New-Item -ItemType Directory -Force .github\task\archive | Out-Null
  Move-Item .github\task\context.md (".github\task\archive\{0}-context.md" -f (Get-Date -Format 'yyyy-MM-dd-HHmm')) -Force
  Write-Host "task data archived to .github\task\archive\"
}

if (-not (Test-Path .gitignore) -or -not (Select-String -Path .gitignore -Pattern '^\.github/task/' -Quiet)) {
  Add-Content .gitignore "`n.github/task/"
}

Write-Host "Task Pipeline installed/updated."
Write-Host "  Reload VS Code -> pick 'Context Getter' in the Copilot agent picker."
