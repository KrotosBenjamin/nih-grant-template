param(
    [ValidateSet('r01', 'r03', 'r21', 'dp2', 'r35')]
    [string]$Profile = 'r01'
)

$ErrorActionPreference = 'Stop'
$env:QUARTO_PROFILE = $Profile

$Python = if (Get-Command python3 -ErrorAction SilentlyContinue) {
    'python3'
} else {
    'python'
}

& $Python scripts/check_profile_compliance.py $Profile
if ($LASTEXITCODE -ne 0) {
    throw "Preflight failed for profile '$Profile'."
}

$ProfileVars = & $Python scripts/profile_params.py $Profile
if ($LASTEXITCODE -ne 0) {
    throw "Could not load Quarto profile '$Profile'."
}

$Vars = @{}
foreach ($Line in $ProfileVars) {
    if ($Line -match '^([A-Za-z0-9_]+) := (.*)$') {
        $Vars[$Matches[1]] = $Matches[2]
    }
}

$Sections = @($Vars['SECTIONS'] -split '\s+' | Where-Object { $_ })
New-Item -ItemType Directory -Force -Path _out/sections | Out-Null

foreach ($File in $Sections) {
    $Name = [System.IO.Path]::GetFileNameWithoutExtension($File)
    Write-Host "Rendering $File ..."
    & quarto render $File --to pdf --output-dir _out/sections -o "$Name.pdf"
    if ($LASTEXITCODE -ne 0) {
        throw "Quarto failed while rendering '$File'."
    }
}

function Test-PageLimit {
    param(
        [string]$LimitName,
        [string[]]$Candidates
    )

    if (-not $Vars.ContainsKey($LimitName)) {
        return
    }

    foreach ($Candidate in $Candidates) {
        if ($Sections -notcontains "src/sections/$Candidate.qmd") {
            continue
        }
        $Pdf = "_out/sections/$Candidate.pdf"
        if (Test-Path $Pdf) {
            & $Python scripts/check_pages.py $Pdf $Vars[$LimitName]
            if ($LASTEXITCODE -ne 0) {
                throw "Page-limit check failed for '$Pdf'."
            }
            return
        }
    }

    throw "$LimitName is declared, but no matching PDF was rendered."
}

Test-PageLimit 'LIMIT_abstract' @('01-project-summary')
Test-PageLimit 'LIMIT_narrative' @('02-project-narrative')
Test-PageLimit 'LIMIT_aims' @('03-specific-aims')
Test-PageLimit 'LIMIT_strategy' @(
    '04-research-strategy',
    '04-research-strategy-dp2',
    '04-research-strategy-mira'
)
Test-PageLimit 'LIMIT_facilities' @('06-facilities')
Test-PageLimit 'LIMIT_dms' @('08-data-management-sharing')

Write-Host "All $Profile sections rendered and checked."
