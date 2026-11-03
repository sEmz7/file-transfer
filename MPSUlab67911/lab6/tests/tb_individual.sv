`timescale 1ns / 1ps
module tb_individual;
  logic clk = 0;
  logic rst = 1;
  logic test_passed = 0;
  processor_system DUT (.clk_i(clk), .rst_i(rst));
  always #5 clk = ~clk;
  initial begin
    repeat (3) @(negedge clk);
    rst = 0;
    repeat (100) @(negedge clk);
    if (DUT.core.register_file.rf_mem[10] !== 32'd6 ||
        DUT.data_mem.ram[0] !== 32'd6)
      $fatal(1, "Variant 21: expected x10 = RAM[0] = 6");
    test_passed = 1;
    $display("PASS variant 21: x10 = RAM[0] = 6");
    $finish;
  end
endmodule
