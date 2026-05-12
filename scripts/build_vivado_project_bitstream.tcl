set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
set project_path [file join $root_dir "vivado" "python1300_cam" "python1300_cam.xpr"]

if {![file exists $project_path]} {
  error "Vivado project not found: $project_path. Run scripts/create_vivado_project.ps1 first."
}

open_project $project_path
set_property source_mgmt_mode None [current_project]
set_property top sei_pin_cam_a_top [get_filesets sources_1]
set_property top_file [file join $root_dir "src" "rtl" "sei_pin_cam_a_top.sv"] [get_filesets sources_1]
update_compile_order -fileset sources_1

reset_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 16
wait_on_run impl_1

if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
  error "impl_1 did not complete"
}

set status [get_property STATUS [get_runs impl_1]]
if {[string first "Complete" $status] < 0} {
  error "impl_1 failed with status: $status"
}

puts "Project bitstream build completed: $status"
