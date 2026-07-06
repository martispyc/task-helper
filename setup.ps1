# Task Pipeline setup — run from the repo root with the transferred *.txt files present.
# First rename setup.ps1.txt -> setup.ps1 by hand, then:
#   powershell -ExecutionPolicy Bypass -File setup.ps1

$ErrorActionPreference = 'Stop'

$agents  = 'context-getter.agent.md','planner.agent.md','implementer.agent.md','review.agent.md'
$support = 'context-template.md','framework-rules.md','context-example.md'

New-Item -ItemType Directory -Force .github\agents, .github\task-helper, .github\task | Out-Null

# strip the .txt transfer suffix (setup files excluded)
Get-ChildItem -File *.txt |
  Where-Object { $_.Name -match '\.(md|html|sh)\.txt$' } |
  ForEach-Object { Rename-Item $_ ($_.Name -replace '\.txt$','') -Force }

foreach ($f in $agents)  { if (Test-Path $f) { Move-Item $f ".github\agents\$f"      -Force } }
foreach ($f in $support) { if (Test-Path $f) { Move-Item $f ".github\task-helper\$f" -Force } }
# task-dashboard.html and README.md stay in the repo root

if (-not (Test-Path .gitignore) -or -not (Select-String -Path .gitignore -Pattern '^\.github/task/' -Quiet)) {
  Add-Content .gitignore "`n.github/task/"
}

Write-Host ""
Write-Host "Done."
Write-Host "  1. Reload VS Code -> pick 'Context Getter' in the Copilot agent picker."
Write-Host "  2. Dashboard: open task-dashboard.html in Edge."
Write-Host "  (Admins: enable the Claude Opus 4.8 model policy in Copilot settings.)"
