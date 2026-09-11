# Export every printable part to hardware/stl and render preview PNGs.
# Usage: powershell -ExecutionPolicy Bypass -File render.ps1 [-OpenScad F:\openscad-2021.01\openscad.com]
param(
  [string]$OpenScad = "F:\openscad-2021.01\openscad.com"
)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
New-Item -ItemType Directory -Force stl | Out-Null

$parts = @("base", "base_lid", "yoke", "head", "head_lid")
foreach ($p in $parts) {
  Write-Host "== $p"
  & $OpenScad -o "stl\$p.stl" -D "part=`"$p`"" turret.scad
}

Write-Host "== previews"
& $OpenScad -o "stl\assembly.png" --imgsize=1600,1200 --camera=140,-170,150,0,0,60 --projection=p --colorscheme=Tomorrow -D 'part="assembly"' turret.scad
& $OpenScad -o "stl\plate.png"    --imgsize=1600,1100 --camera=45,-190,280,45,45,0 --projection=o --colorscheme=Tomorrow -D 'part="plate"' turret.scad
Write-Host "done -> stl\"
