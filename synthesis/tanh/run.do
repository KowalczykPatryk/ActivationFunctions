setup_design -manufacturer Xilinx -family Artix-7 -part 7A100TCSG324

foreach f $::argv {
    add_input_file $f
}

compile

create_clock -period 1 clk
set_input_delay  -clock clk 0 [all_inputs]
set_output_delay -clock clk 0 [all_outputs]

synthesize
report_area
report_timing