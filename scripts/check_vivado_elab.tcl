set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]

set_part xczu3eg-sfvc784-1-i

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
synth_design -rtl -top sei_pin_cam_a_top -part xczu3eg-sfvc784-1-i
report_compile_order -used_in synthesis
