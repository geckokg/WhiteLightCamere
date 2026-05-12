# Register Initialization Notes

The current initialization ROM is in `src/rtl/python1300_init_rom.sv`.

## Current Sequence

- Read `chip_id` at address `0`, expecting `0x50D0`.
- Enable clock input path and PLL from the 72 MHz `clk_pll` pin.
- Poll PLL lock at address `24`, bit `0`.
- Enable clock generator, logic, bias, charge pump, image core, AFE, and LVDS outputs.
- Program default 10-bit training/sync values:
  - training data: `0x3A6`
  - frame sync LSB: `0x2A`
  - BL: `0x015`
  - IMG: `0x035`
  - CRC: `0x059`
  - TR: `0x3A6`
- Configure ROI0 as full frame: x kernels `0..159`, y `0..1023`.
- Set fixed exposure/gain placeholders.
- Enable the sequencer as the final write.

## Known Gap

The datasheet mentions a required reserved-register upload, but the supplied PDF does not include a complete Developer Guide style preset table. Treat the ROM as a bring-up starting point. If you obtain onsemi AND9362 / Developer Guide values or a vendor-provided register dump, replace or prepend those writes in the ROM before expecting final image quality.

## Safe Edit Point

For power-only testing, comment out or remove ROM index `32`, the final `REG_SEQ_CONFIG = 0x0001` write, so the sensor reaches idle but does not stream image data.
