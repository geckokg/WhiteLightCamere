# CAM A ILA Probe Map

Build the ILA bring-up image with:

```powershell
.\scripts\build_ila_pin_bringup_bitstream.ps1
```

Program both files in Vivado Hardware Manager:

```text
D:\ZYNQ\WhiteLightCamere\out\ila_pin_bringup\sei_pin_cam_a_top_ila.bit
D:\ZYNQ\WhiteLightCamere\out\ila_pin_bringup\sei_pin_cam_a_top_ila.ltx
```

The ILA uses `sys_clk` as its sample clock and exposes one 128-bit probe, `probe0`.
The default depth is 8192 samples, about 82 us at 100 MHz.

## `probe0` Bits

| Bit range | Meaning |
| --- | --- |
| 0 | MMCM locked |
| 1 | internal reset released |
| 2 | camera 1.8 V enable output |
| 3 | camera 3.3 V enable output |
| 4 | internal pixel/analog rail enable state |
| 5 | camera reset_n output |
| 6 | camera clock enable command |
| 7 | trigger_0 output |
| 8 | SPI SCK |
| 9 | SPI SS_N |
| 10 | SPI MOSI |
| 11 | SPI MISO |
| 12 | power sequence done |
| 13 | register init done |
| 14 | chip_id read matched 0x50D0 |
| 15 | register init fault |
| 23:16 | register init ROM index |
| 31:24 | register init fault code |
| 32 | internal pixel/analog rail enable state duplicate |
| 33 | camera clock enable command duplicate |
| 127:34 | reserved |

Useful first triggers:

- Power sequencing: trigger on bit 2 rising, then check bits 2, 3, 4, 5, 6, 12.
- SPI activity: trigger on bit 9 falling, then check bits 8, 9, 10, 11.
- Chip ID result: trigger on bit 14 rising. If bit 15 rises instead, inspect bits 31:24 for the init fault code.
- LVDS activity is intentionally not in this first ILA image. This image is for safe power/reset/SPI bring-up. Add a second LVDS-specific ILA after the SelectIO/IDELAY receiver replaces the current scaffold.

ILA does not prove the actual rail voltage on the camera board. It only proves what the FPGA is commanding and receiving digitally.
