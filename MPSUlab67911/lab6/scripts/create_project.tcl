# Run in Vivado Tcl Console. Paths are resolved relative to this script.
# Default: the unmodified upstream lab 11 testbench.
# Optional: set lab6_test lab07|lab09|lab11|selftest|individual|memory|lsu|csr|irq|board
set lab6_root [file normalize [file join [file dirname [info script]] ..]]
if {![info exists lab6_test]} {
    if {[info exists argv] && [llength $argv] > 0} {
        set lab6_test [lindex $argv 0]
    } else {
        set lab6_test lab11
    }
}
set lab6_tests [dict create \
    selftest   {tb_lab6 tests/tb_lab6.sv} \
    individual {tb_individual tests/tb_individual.sv} \
    lab07      {lab_07_tb_processor_system tests/upstream/lab_07.tb_processor_system.sv} \
    lab09      {lab_07_tb_processor_system tests/upstream/lab_07.tb_processor_system.sv} \
    lab11      {lab_11_tb_processor_system tests/upstream/lab_11.tb_processor_system.sv} \
    memory     {lab_06_tb_data_mem tests/upstream/lab_06.tb_data_mem.sv} \
    lsu        {lab_08_tb_lsu tests/upstream/lab_08.tb_lsu.sv} \
    csr        {lab_10_tb_csr tests/upstream/lab_10.tb_csr.sv} \
    irq        {lab_10_tb_irq tests/upstream/lab_10.tb_irq.sv}]
if {$lab6_test ne "board" && ![dict exists $lab6_tests $lab6_test]} {
    error "Unknown lab6_test: $lab6_test"
}
if {[llength [get_projects -quiet]] != 0} {
    error "Close the current Vivado project before creating the lab 6 project."
}
set lab6_build [file join $lab6_root .vivado $lab6_test]
file mkdir $lab6_build
create_project -force lab6_$lab6_test $lab6_build -part xc7a100tcsg324-1
set_property target_language Verilog [current_project]
set_property target_simulator XSim [current_project]

set lab6_handle [open [file join $lab6_root sources.f] r]
set lab6_lines [split [read $lab6_handle] "\n"]
close $lab6_handle
foreach relative $lab6_lines {
    set relative [string trim $relative]
    if {$relative eq ""} {continue}
    set source_file [file join $lab6_root $relative]
    if {![file isfile $source_file]} {error "Missing source: $source_file"}
    add_files -norecurse -fileset sources_1 $source_file
    set_property file_type SystemVerilog [get_files $source_file]
}
set_property top processor_system [get_filesets sources_1]

set lab6_program lab11
if {$lab6_test in {lab07 lab09}} {set lab6_program lab07}
if {$lab6_test eq "individual" || $lab6_test eq "board"} {set lab6_program individual}
set lab6_memdir [file join $lab6_build images]
file mkdir $lab6_memdir
set lab6_program_file [file join $lab6_memdir program.mem]
file copy -force [file join $lab6_root programs $lab6_program.mem] $lab6_program_file
add_files -norecurse -fileset sources_1 $lab6_program_file
set_property file_type {Memory Initialization Files} [get_files $lab6_program_file]

if {$lab6_test eq "board"} {
    add_files -norecurse -fileset sources_1 [file join $lab6_root board nexys_riscv_unit.sv]
    add_files -norecurse -fileset constrs_1 [file join $lab6_root board nexys_a7_100t.xdc]
    set_property top nexys_processor_system [get_filesets sources_1]
    puts "Board project ready. Program: individual (variant 21)."
} else {
    lassign [dict get $lab6_tests $lab6_test] lab6_top lab6_relative_bench
    set lab6_bench [file join $lab6_root $lab6_relative_bench]
    # Configure the design checkpoint, leaving the upstream testbench intact.
    if {$lab6_test in {lab07 lab09}} {
        set_property verilog_define {APS_DATAPATH_CHECKPOINT} [get_filesets sim_1]
    }
    add_files -norecurse -fileset sim_1 $lab6_bench
    set_property file_type SystemVerilog [get_files $lab6_bench]
    # All stimulus images have unique basenames and are copied into XSim's
    # working directory by Vivado as memory initialization files.
    foreach pattern {programs/*.mem tests/programs/*.mem} {
        foreach image [glob -nocomplain [file join $lab6_root $pattern]] {
            if {[file tail $image] eq "peripherals_original.mem"} {continue}
            add_files -norecurse -fileset sim_1 $image
            set_property file_type {Memory Initialization Files} [get_files $image]
        }
    }
    set_property top $lab6_top [get_filesets sim_1]
    set_property xsim.elaborate.debug_level all [get_filesets sim_1]
    set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
    set_property xsim.simulate.log_all_signals true [get_filesets sim_1]
    update_compile_order -fileset sim_1
    puts "Simulation project ready: $lab6_top. Run launch_simulation, then run all."
}
update_compile_order -fileset sources_1
puts "Project: [file join $lab6_build lab6_$lab6_test.xpr]"
