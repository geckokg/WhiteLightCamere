$ErrorActionPreference = "Stop"

$VivadoBat = "D:\Xilinx\Vivado\2024.2\bin\vivado.bat"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Resolve-Path (Join-Path $ScriptDir "..")
$ExtractXdcScript = Join-Path $ScriptDir "extract_sei_cam_a_xdc.py"
$TclScript = Join-Path $ScriptDir "check_vivado_elab.tcl"

Push-Location $RootDir
try {
    py $ExtractXdcScript
    & $VivadoBat -mode batch -source $TclScript
}
finally {
    Pop-Location
}
