$ErrorActionPreference = "Stop"

$VivadoBat = "D:\Xilinx\Vivado\2024.2\bin\vivado.bat"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Resolve-Path (Join-Path $ScriptDir "..")
$TclScript = Join-Path $ScriptDir "build_pin_bringup_bitstream.tcl"
$ExtractXdcScript = Join-Path $ScriptDir "extract_sei_cam_a_xdc.py"

if (!(Test-Path $VivadoBat)) {
    throw "Vivado was not found at $VivadoBat"
}

Push-Location $RootDir
try {
    py $ExtractXdcScript
    & $VivadoBat -mode batch -source $TclScript
}
finally {
    Pop-Location
}
