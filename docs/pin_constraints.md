# Pin Constraint Source

The active camera constraint source is:

```text
D:\ZYNQ\lasercom\lasercom_top\Sei_Pin.xdc
```

The project does not add that file verbatim because it contains old hierarchy-specific `get_nets` constraints and many unrelated SDI/UART/CAM B ports. Instead, `scripts/extract_sei_cam_a_xdc.py` extracts the sys clock and CAM A `get_ports` constraints into:

```text
constraints\sei_pin_cam_a.generated.xdc
```

## CAM A Pin Use

CAM A uses enough pins for one NOIP1SN1300A P1 link:

- 5 LVDS differential pairs: sensor output clock, sync, data0..data3
- 4 SPI pins: `spi_sck`, `spi_ss_n`, `spi_mosi`, `spi_miso`
- 1 reset pin: `camera_reset_n`
- 2 power enables: `camera_vdd_18_en`, `camera_vdd_33_en`
- 1 72 MHz reference clock output: `camera_lvds_clk`
- 1 optional trigger output: `trigger_0`

That is 19 physical camera-side pins for CAM A, plus the 100 MHz differential system clock.

## PS/PL Pin Note

Moving control to PS only saves physical pins if the board actually routes those signals to PS MIO or to an already-routed peripheral such as an I2C/SPI GPIO expander. If the signals are routed to PL pins as shown in `Sei_Pin.xdc`, moving them to PS through EMIO still consumes PL pins.

The high-speed LVDS image data must remain in PL; PS is not a practical replacement for the LVDS capture pins.
