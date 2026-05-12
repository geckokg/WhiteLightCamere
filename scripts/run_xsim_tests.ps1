$ErrorActionPreference = "Stop"

$VivadoBin = "D:\Xilinx\Vivado\2024.2\bin"
$RootDir = Resolve-Path (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "..")
$SimRoot = "D:\codex\tmp\WhiteLightCamere_xsim"

function Invoke-Step {
    param(
        [string] $Name,
        [scriptblock] $Command
    )
    Write-Host "== $Name =="
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE"
    }
}

function Invoke-XsimTest {
    param(
        [string] $Top,
        [string[]] $Files
    )

    $WorkDir = Join-Path $SimRoot $Top
    Remove-Item -Recurse -Force $WorkDir -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null

    Push-Location $WorkDir
    try {
        $AbsFiles = $Files | ForEach-Object { Join-Path $RootDir $_ }
        Invoke-Step "$Top xvlog" { & (Join-Path $VivadoBin "xvlog.bat") -sv @AbsFiles }
        Invoke-Step "$Top xelab" { & (Join-Path $VivadoBin "xelab.bat") $Top -s "${Top}_sim" }

        $LogPath = Join-Path $WorkDir "xsim_output.log"
        Write-Host "== $Top xsim =="
        & (Join-Path $VivadoBin "xsim.bat") "${Top}_sim" -runall | Tee-Object -FilePath $LogPath
        if ($LASTEXITCODE -ne 0) {
            throw "$Top xsim failed with exit code $LASTEXITCODE"
        }

        $Log = Get-Content $LogPath -Raw
        if ($Log -match "(?m)^(Fatal:|Error:|ERROR:)") {
            throw "$Top simulation reported a fatal/error line"
        }
        if ($Log -notmatch "$Top PASS") {
            throw "$Top did not print PASS"
        }
    }
    finally {
        Pop-Location
    }
}

Invoke-XsimTest "tb_power_seq" @(
    "src/rtl/cam_power_seq.sv",
    "tb/tb_power_seq.sv"
)

Invoke-XsimTest "tb_frame_path" @(
    "src/rtl/python1300_pkg.sv",
    "src/rtl/python1300_frame_parser.sv",
    "src/rtl/python1300_kernel_reorder.sv",
    "tb/tb_frame_path.sv"
)

Write-Host "All xsim tests passed."
