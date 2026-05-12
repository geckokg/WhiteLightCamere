set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
set project_path [file join $root_dir "vivado" "python1300_cam" "python1300_cam.xpr"]
set top_name sei_pin_cam_a_top
set top_file [file join $root_dir "src" "rtl" "sei_pin_cam_a_top.sv"]

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

if {[llength [get_projects -quiet]] == 0} {
  if {![file exists $project_path]} {
    error "Vivado project not found: $project_path. Run scripts/create_vivado_project.ps1 first."
  }
  open_project $project_path
}

set srcset [get_filesets sources_1]
set constrset [get_filesets constrs_1]
set_property source_mgmt_mode None [current_project]
set_property XPM_LIBRARIES {XPM_CDC XPM_FIFO XPM_MEMORY} [current_project]

foreach f $rtl_files {
  set full_path [file join $root_dir $f]
  if {[llength [get_files -quiet $full_path]] == 0} {
    add_files -fileset $srcset -norecurse $full_path
  }
}

foreach f [get_files -quiet -of_objects $constrset] {
  set_property is_enabled false $f
}

set cam_a_xdc [file join $root_dir "constraints" "sei_pin_cam_a.generated.xdc"]
if {[llength [get_files -quiet $cam_a_xdc]] == 0} {
  add_files -fileset $constrset -norecurse $cam_a_xdc
}
set_property is_enabled true [get_files $cam_a_xdc]

set_property top $top_name $srcset
set_property top_file $top_file $srcset
set_property top_auto_set 0 $srcset

update_compile_order -fileset sources_1
close_project

puts "Repaired Vivado project top: $top_name"
puts "Reset synth_1/impl_1 before rebuilding, or run scripts/build_pin_bringup_bitstream.ps1 for the known-good pin bring-up bitstream."
