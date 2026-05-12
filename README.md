# NOIP1SN1300A White Camera FPGA Driver

This workspace contains a first-pass PL driver scaffold for an onsemi PYTHON 1300 / `NOIP1SN1300A` camera on `xczu3eg-sfvc784-1-i`.

Canonical local workspace:

```text
D:\ZYNQ\WhiteLightCamere
```

The implemented target is:

- P1 LVDS output, 4 data lanes + sync + clock
- Monochrome, 1280 x 1024, 10-bit pixels
- PL-controlled power/reset/SPI/LVDS/frame capture
- AXI4 master writes one frame into PS DDR as 16-bit pixels, low 10 bits valid
- PS is only expected to initialize DDR and export the captured frame

## Layout

- `src/rtl/` - SystemVerilog RTL
- `constraints/` - commented J31 constraint template
- `scripts/create_vivado_project.tcl` - creates a Vivado project shell
- `scripts/create_vivado_project.ps1` - runs Vivado 2024.2 from `D:\Xilinx\Vivado\2024.2`
- `scripts/extract_sei_cam_a_xdc.py` - extracts CAM A constraints from `D:\ZYNQ\lasercom\lasercom_top\Sei_Pin.xdc`
- `scripts/run_xsim_tests.ps1` - runs the current Vivado xsim RTL testbenches
- `scripts/raw16_to_pgm.py` - converts a raw DDR frame dump to PGM
- `tb/` - small simulation benches for power sequencing and frame parsing
- `docs/` - hardware preflight and bring-up notes

## Important Hardware Note

The supplied main-board schematic page shows SPI `MOSI/MISO/SCK` but no obvious `ss_n` on J31. The top exposes `cam1_ss_n` and also supports `USE_TRIGGER0_AS_SS_N=1`, which drives `TRIGGER0` with SPI chip-select for temporary bring-up if you confirm that this is electrically safe on the camera board.

The LVDS receiver module is intentionally a stable interface wrapper. For real 720 Mbps/lane hardware use, replace the internals of `python1300_lvds_rx.sv` with a Vivado SelectIO/IDELAY implementation that emits the same `word_valid + 5x10-bit words` interface.

## Vivado Start

From PowerShell in the workspace:

```powershell
.\scripts\create_vivado_project.ps1
```

Or from Vivado Tcl:

```tcl
source scripts/create_vivado_project.tcl
```

The generated Vivado project is placed under:

```text
D:\ZYNQ\WhiteLightCamere\vivado\python1300_cam
```

The default Vivado top is `sei_pin_cam_a_top`, which matches the CAM A port names in `Sei_Pin.xdc`.
It is a pin-level bring-up top: it generates the 72 MHz camera clock from the 100 MHz board clock and uses an internal AXI sink so no DDR pins are exposed.

For a quick Vivado RTL elaboration check:

```powershell
.\scripts\check_vivado_elab.ps1
```

For RTL simulation:

```powershell
.\scripts\run_xsim_tests.ps1
```

To generate the current CAM A pin-level bring-up bitstream without relying on the GUI project's selected top module:

```powershell
.\scripts\build_pin_bringup_bitstream.ps1
```

The bitstream is written to:

```text
D:\ZYNQ\WhiteLightCamere\out\pin_bringup\sei_pin_cam_a_top.bit
```

Current simulation coverage:

- `tb_power_seq` checks sensor rail/clock/reset sequencing.
- `tb_frame_path` checks sync-code parsing and 4-lane kernel pixel reorder.

For real DDR frame capture, keep using `cam_python1300_top` inside a Zynq MPSoC block design and connect its AXI master to a PS HP/HPC DDR port:

- Zynq UltraScale+ MPSoC
- PL clock for `sys_clk`, default 100 MHz
- Clocking Wizard output for `cam_ref_clk_72m`
- AXI HP/HPC path from `cam_python1300_top` to DDR
