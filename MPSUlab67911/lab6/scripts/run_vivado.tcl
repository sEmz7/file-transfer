# vivado -mode batch -source scripts/run_vivado.tcl -tclargs lab11
# Use -tclargs all to run the upstream benches for lab parts 7, 9 and 11.
set lab6_script_dir [file dirname [file normalize [info script]]]
set lab6_requested lab11
if {[llength $argv] > 0} {set lab6_requested [lindex $argv 0]}
if {$lab6_requested eq "all"} {
    set lab6_selected {lab07 lab09 lab11}
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
            # The original CSR testbench includes an interactive pause at 0.
            if {$lab6_test eq "csr"} {run 100 ns}
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
            if {$lab6_test in {lab07 lab09 lab11}} {
                puts "Completed original MPSU/APS testbench: $lab6_test. Inspect the waveform as required by the assignment."
            } else {
                puts "PASS $lab6_test"
            }
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
