set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
set build_dir [file join $root_dir "build" "ila_pin_bringup"]
set out_dir [file join $root_dir "out" "ila_pin_bringup"]

file mkdir $build_dir
file mkdir $out_dir
cd $build_dir

create_project -in_memory -part xczu3eg-sfvc784-1-i
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]
set_property XPM_LIBRARIES {XPM_CDC XPM_FIFO XPM_MEMORY} [current_project]

set rtl_files {
  src/rtl/python1300_pkg.sv
  src/rtl/clk_mmcm_100_to_72.sv
  src/rtl/cam_power_seq.sv
  src/rtl/python1300_spi_master.sv
  src/rtl/python1300_init_rom.sv
  src/rtl/python1300_init_ctrl.sv
  src/rtl/python1300_lvds_rx.sv
  src/rtl/python1300_frame_parser.sv
  src/rtl/python1300_kernel_reorder.sv
  src/rtl/async_fifo_gray.sv
  src/rtl/axi_frame_writer.sv
  src/rtl/axi_write_sink.sv
  src/rtl/cam_python1300_top.sv
  src/rtl/sei_pin_cam_a_top.sv
}

foreach f $rtl_files {
  read_verilog -sv [file join $root_dir $f]
}

read_xdc [file join $root_dir "constraints" "sei_pin_cam_a.generated.xdc"]

synth_design -top sei_pin_cam_a_top -part xczu3eg-sfvc784-1-i

set dbg_clk [get_nets -quiet sys_clk]
if {[llength $dbg_clk] != 1} {
  error "Expected exactly one sys_clk net, found [llength $dbg_clk]"
}

set dbg_bus_nets {}
for {set i 0} {$i < 128} {incr i} {
  set bit_name [format {dbg_sys_bus[%d]} $i]
  set bit_net [get_nets -quiet $bit_name]
  if {[llength $bit_net] != 1} {
    error "Expected exactly one $bit_name net, found [llength $bit_net]"
  }
  lappend dbg_bus_nets $bit_net
}

create_debug_core u_ila_cam_a ila
set_property C_DATA_DEPTH 8192 [get_debug_cores u_ila_cam_a]
set_property C_INPUT_PIPE_STAGES 1 [get_debug_cores u_ila_cam_a]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_cam_a]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_cam_a]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_cam_a]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_cam_a]
connect_debug_port u_ila_cam_a/clk $dbg_clk
set_property port_width 128 [get_debug_ports u_ila_cam_a/probe0]
connect_debug_port u_ila_cam_a/probe0 $dbg_bus_nets

write_checkpoint -force [file join $out_dir "sei_pin_cam_a_top_ila_synth.dcp"]
report_utilization -file [file join $out_dir "sei_pin_cam_a_top_ila_utilization_synth.rpt"]

opt_design
place_design
phys_opt_design
route_design

report_drc -file [file join $out_dir "sei_pin_cam_a_top_ila_drc_routed.rpt"]
report_timing_summary -max_paths 10 -report_unconstrained -file [file join $out_dir "sei_pin_cam_a_top_ila_timing_summary_routed.rpt"]
report_route_status -file [file join $out_dir "sei_pin_cam_a_top_ila_route_status.rpt"]
write_debug_probes -force [file join $out_dir "sei_pin_cam_a_top_ila.ltx"]
write_checkpoint -force [file join $out_dir "sei_pin_cam_a_top_ila_routed.dcp"]
write_bitstream -force [file join $out_dir "sei_pin_cam_a_top_ila.bit"]

puts "Wrote ILA bitstream: [file join $out_dir sei_pin_cam_a_top_ila.bit]"
puts "Wrote ILA probes:    [file join $out_dir sei_pin_cam_a_top_ila.ltx]"
