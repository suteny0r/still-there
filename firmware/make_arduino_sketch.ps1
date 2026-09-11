# Assemble an Arduino-IDE sketch folder from the PlatformIO sources.
# Output: firmware/arduino/turret/turret.ino + all .h/.cpp side by side.
#
# Build in the IDE with: Tools > Board > esp32 > XIAO_ESP32S3, PSRAM: "OPI PSRAM".
# Or with arduino-cli:
#   arduino-cli compile --fqbn esp32:esp32:XIAO_ESP32S3:PSRAM=opi arduino/turret
#
# Note: arduino-esp32 3.x has no esp-dl, so face tracking is compiled out there
# (motion tracking, scan and manual modes still work). Use PlatformIO for face tracking.
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
$out = "arduino\turret"
New-Item -ItemType Directory -Force $out | Out-Null
Get-ChildItem "$out\*" -Include *.h,*.cpp,*.ino | Remove-Item -Force
Copy-Item include\*.h $out
if (Test-Path include\secrets.h) { Copy-Item include\secrets.h $out -Force }
Get-ChildItem src\*.h, src\*.cpp | Where-Object { $_.Name -ne "main.cpp" } | Copy-Item -Destination $out
Copy-Item src\main.cpp "$out\turret.ino"
Write-Host "sketch written to $out"
