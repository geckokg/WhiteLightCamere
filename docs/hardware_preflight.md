# Hardware Preflight

Before programming an image-capture build, confirm these points on the real camera board with power off unless noted.

## Required Checks

- Confirm whether sensor pin `ss_n` reaches the connector. The main-board page for J31 does not clearly show it.
- If `ss_n` is not routed, decide whether `TRIGGER0` can be safely repurposed or whether a fly-wire/board change is needed.
- Confirm `CLK_PLL`, `MOSI`, `SCK`, `RESET_N`, and optional `ss_n` voltage levels. The ZU3EG Bank66 side is 1.8 V in the schematic, while the sensor datasheet lists CMOS I/O as 3.3 V.
- Confirm whether the camera board includes level shifting between the connector and the sensor.
- Confirm `VDD_1V8_EN`, `VDD_3V3_EN`, and the analog/pixel rail relationship. The RTL sequences an internal `vdd_pix_en`, but the visible connector only exposes 1.8 V and 3.3 V enables.
- With a power-limited bench supply, verify current draw after each enable step before releasing reset.

## First Power Build

Use only the power/reset/clock path first:

- `VDD_1V8_EN` high
- wait at least 10 us
- `VDD_3V3_EN` high
- wait at least 10 us
- camera 72 MHz `CLK_PLL` enabled
- wait at least 10 us
- `RESET_N` high

Scope `CLK_PLL`, `RESET_N`, the two enables, and the actual sensor rails.

## Do Not Skip

Do not drive the sensor CMOS pins until the voltage-level path is understood. If the board lacks level shifting and the sensor expects 3.3 V CMOS, direct 1.8 V Bank66 control may not meet VIH, and direct 3.3 V back-drive into the FPGA bank would be unsafe.
