param([ValidateSet('r01','r03','r21')][string]$Profile='r01')
$env:QUARTO_PROFILE = $Profile
quarto render
Write-Host "Rendered with profile: $Profile -> _out/"
