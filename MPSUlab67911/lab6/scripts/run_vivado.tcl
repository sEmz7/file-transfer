# vivado -mode batch -source scripts/run_vivado.tcl -tclargs selftest
# Use -tclargs all to run all simulation testbenches.
set lab6_script_dir [file dirname [file normalize [info script]]]
set lab6_requested selftest
if {[llength $argv] > 0} {set lab6_requested [lindex $argv 0]}
if {$lab6_requested eq "all"} {
    set lab6_selected {selftest individual memory lsu csr irq lab07 lab11}
} else {
    set lab6_selected [list $lab6_requested]
}
if {[catch {
    foreach lab6_test $lab6_selected {
        source [file join $lab6_script_dir create_project.tcl]
        if {$lab6_test eq "board"} {
            puts "Board project created; synthesis and board programming are separate steps."
        } else {
            launch_simulation -simset sim_1 -mode behavioral
            run all
            if {$lab6_test eq "selftest" || $lab6_test eq "individual"} {
                if {[get_value -radix unsigned /$lab6_top/test_passed] != 1} {
                    error "Simulation did not reach PASS: $lab6_test"
                }
            } elseif {$lab6_test in {memory lsu csr irq}} {
                set lab6_error_name err_count
                if {$lab6_test eq "memory"} {set lab6_error_name err_cnt}
                if {[get_value -radix unsigned /$lab6_top/$lab6_error_name] != 0} {
                    error "Simulation reported errors: $lab6_test"
                }
            }
            puts "PASS $lab6_test"
            close_sim
        }
        close_project
    }
} lab6_error]} {
    puts stderr "FAIL: $lab6_error"
    exit 1
}
puts "All requested Vivado simulations completed."
exit 0
