## Template only. Verify every package pin against the final schematic before using.
## Bank66 is shown as PL_VDD1V8_IO66 in the supplied main-board schematic.

## Clocks supplied by the Zynq MPSoC / Clocking Wizard block design.
# create_clock -period 10.000 [get_ports sys_clk]
# create_clock -period 13.889 [get_ports cam_ref_clk_72m]

## Camera 1 CMOS control signals.
# set_property PACKAGE_PIN C3 [get_ports cam1_mosi]
# set_property PACKAGE_PIN D3 [get_ports cam1_miso]
# set_property PACKAGE_PIN B4 [get_ports cam1_sck]
# set_property PACKAGE_PIN A4 [get_ports cam1_reset_n]
# set_property PACKAGE_PIN F3 [get_ports cam1_clk_pll]
# set_property PACKAGE_PIN G4 [get_ports cam1_trigger0]
# set_property PACKAGE_PIN F5 [get_ports cam1_trigger1]
# set_property PACKAGE_PIN G5 [get_ports cam1_trigger2]
# set_property IOSTANDARD LVCMOS18 [get_ports {cam1_mosi cam1_miso cam1_sck cam1_reset_n cam1_clk_pll cam1_trigger0 cam1_trigger1 cam1_trigger2}]

## ss_n is not clearly present on J31 in the schematic page. Either fly-wire it,
## confirm a hidden net, or set USE_TRIGGER0_AS_SS_N=1 and map trigger0 to ss_n.
# set_property PACKAGE_PIN <VERIFY_SS_N_PIN> [get_ports cam1_ss_n]
# set_property IOSTANDARD LVCMOS18 [get_ports cam1_ss_n]

## Camera 1 power enables.
# set_property PACKAGE_PIN <VERIFY_1V8_EN_PIN> [get_ports cam1_vdd_1v8_en]
# set_property PACKAGE_PIN <VERIFY_3V3_EN_PIN> [get_ports cam1_vdd_3v3_en]
# set_property IOSTANDARD LVCMOS18 [get_ports {cam1_vdd_1v8_en cam1_vdd_3v3_en}]

## Camera 1 LVDS outputs from sensor to FPGA.
## Schematic-read candidates: OUTP D6, OUTN D5, D0P B5, D0N A5,
## D1P B6, D1N A7, D2P C6, D2N C8, D3P B8, D3N A9, SYNCP C9, SYNCN A8.
# set_property PACKAGE_PIN D6 [get_ports cam1_lvds_clk_out_p]
# set_property PACKAGE_PIN D5 [get_ports cam1_lvds_clk_out_n]
# set_property PACKAGE_PIN B5 [get_ports {cam1_lvds_data_p[0]}]
# set_property PACKAGE_PIN A5 [get_ports {cam1_lvds_data_n[0]}]
# set_property PACKAGE_PIN B6 [get_ports {cam1_lvds_data_p[1]}]
# set_property PACKAGE_PIN A7 [get_ports {cam1_lvds_data_n[1]}]
# set_property PACKAGE_PIN C6 [get_ports {cam1_lvds_data_p[2]}]
# set_property PACKAGE_PIN C8 [get_ports {cam1_lvds_data_n[2]}]
# set_property PACKAGE_PIN B8 [get_ports {cam1_lvds_data_p[3]}]
# set_property PACKAGE_PIN A9 [get_ports {cam1_lvds_data_n[3]}]
# set_property PACKAGE_PIN C9 [get_ports cam1_lvds_sync_p]
# set_property PACKAGE_PIN A8 [get_ports cam1_lvds_sync_n]
# set_property IOSTANDARD LVDS [get_ports {cam1_lvds_clk_out_p cam1_lvds_clk_out_n cam1_lvds_data_p[*] cam1_lvds_data_n[*] cam1_lvds_sync_p cam1_lvds_sync_n}]

## LVDS clock input to the sensor is intentionally unused in this first version.
# set_property PACKAGE_PIN <VERIFY_LVDS_CLK_IN_P> [get_ports cam1_lvds_clk_in_p]
# set_property PACKAGE_PIN <VERIFY_LVDS_CLK_IN_N> [get_ports cam1_lvds_clk_in_n]
