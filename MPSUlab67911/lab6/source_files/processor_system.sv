`timescale 1ns / 1ps

// PIN/PM lab 6: datapath, load/store unit and interrupt integration.
module processor_system #(
`ifdef APS_DATAPATH_CHECKPOINT
  parameter bit ENABLE_TRAPS = 1'b0
`else
  parameter bit ENABLE_TRAPS = 1'b1
`endif
) (
  input logic clk_i,
  input logic rst_i
);
  logic [31:0] instr, instr_addr;
  logic [31:0] core_addr, core_wd, core_rd;
  logic [2:0] core_size;
  logic core_req, core_we, stall;
  logic [31:0] mem_addr, mem_wd, mem_rd;
  logic [3:0] mem_be;
  logic mem_req, mem_we, ready;

  // The lab 11 testbench drives this variable hierarchically. Without a
  // peripheral or a testbench, there is no external interrupt source.
  logic irq_req = 1'b0;
  logic irq_ret;

  instr_mem instr_mem (
    .read_addr_i(instr_addr),
    .read_data_o(instr)
  );

  processor_core #(.ENABLE_TRAPS(ENABLE_TRAPS)) core (
    .clk_i(clk_i), .rst_i(rst_i), .stall_i(stall),
    .irq_req_i(irq_req), .instr_i(instr), .mem_rd_i(core_rd),
    .irq_ret_o(irq_ret), .instr_addr_o(instr_addr),
    .mem_addr_o(core_addr), .mem_size_o(core_size),
    .mem_req_o(core_req), .mem_we_o(core_we), .mem_wd_o(core_wd)
  );

  lsu lsu (
    .clk_i(clk_i), .rst_i(rst_i),
    .core_req_i(core_req), .core_we_i(core_we),
    .core_size_i(core_size), .core_addr_i(core_addr), .core_wd_i(core_wd),
    .core_rd_o(core_rd), .core_stall_o(stall),
    .mem_req_o(mem_req), .mem_we_o(mem_we), .mem_be_o(mem_be),
    .mem_addr_o(mem_addr), .mem_wd_o(mem_wd),
    .mem_rd_i(mem_rd), .mem_ready_i(ready)
  );

  data_mem data_mem (
    .clk_i(clk_i), .mem_req_i(mem_req), .write_enable_i(mem_we),
    .byte_enable_i(mem_be), .addr_i(mem_addr), .write_data_i(mem_wd),
    .read_data_o(mem_rd), .ready_o(ready)
  );
endmodule
