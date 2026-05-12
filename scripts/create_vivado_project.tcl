set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
set proj_dir [file join $root_dir "vivado" "python1300_cam"]

create_project python1300_cam $proj_dir -part xczu3eg-sfvc784-1-i -force
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

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
  add_files -norecurse [file join $root_dir $f]
}

add_files -fileset constrs_1 -norecurse [file join $root_dir "constraints" "sei_pin_cam_a.generated.xdc"]
set_property top sei_pin_cam_a_top [current_fileset]
update_compile_order -fileset sources_1

puts "Created Vivado project at $proj_dir"
puts "Top is sei_pin_cam_a_top, using CAM A pins generated from D:/ZYNQ/lasercom/lasercom_top/Sei_Pin.xdc."
puts "For DDR capture, instantiate cam_python1300_top inside a Zynq MPSoC block design and connect its AXI master to an HP/HPC DDR port."
