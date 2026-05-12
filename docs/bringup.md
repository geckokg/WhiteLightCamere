# Bring-Up Checklist

## 1. Power and Clock

- Program a build that only instantiates `cam_power_seq`.
- Verify enable order and rail voltages.
- Verify the 72 MHz `CLK_PLL` reaches the camera board before `RESET_N` deasserts.

## 2. SPI

- Connect or confirm `ss_n`.
- Read `chip_id`; status should show `chip_id_ok=1`.
- If chip ID fails, check chip-select first, then MOSI/SCK polarity, then voltage levels.

## 3. Initialization

- Let `python1300_init_ctrl` run through the ROM.
- Verify `init_done=1`, `init_fault=0`.
- If PLL polling times out, check that `CLK_PLL` is present and that register `16` is appropriate for PLL mode.

## 4. LVDS Training

- After LVDS outputs are enabled, observe `training_seen` then `align_locked`.
- The current `python1300_lvds_rx` is a scaffold; replace it with SelectIO/IDELAY before full-rate capture.
- Lock should be based on stable `0x3A6` words on sync and data lanes.

## 5. Frame Write

- Connect the AXI master to an HP/HPC DDR path.
- Wait for `frame_done_pulse` and `frame_count` increment.
- Dump `1280 * 1024 * 2` bytes from `FRAME_BASE_ADDR`.
- Convert with:

```powershell
py scripts/raw16_to_pgm.py frame.raw frame.pgm
```

## Status Bits

`status[31:0]` packs high-level debug:

- bit 0: power sequence done
- bit 1: init done
- bit 2: chip ID matched
- bit 3: init fault
- bit 4: LVDS training seen
- bit 5: LVDS align locked
- bit 6: frame done pulse
- bit 7: FIFO overflow
- bit 8: AXI error
- bits 16:9: initialization ROM index
- bits 24:17: initialization fault code
