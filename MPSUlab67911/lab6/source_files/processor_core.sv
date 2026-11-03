`timescale 1ns / 1ps

module processor_core #(
  // Disable only for the lab 7/9 checkpoint, before traps are introduced.
  parameter bit ENABLE_TRAPS = 1'b1
) (
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        stall_i,
  input  logic        irq_req_i,
  input  logic [31:0] instr_i,
  input  logic [31:0] mem_rd_i,
  output logic        irq_ret_o,
  output logic [31:0] instr_addr_o,
  output logic [31:0] mem_addr_o,
  output logic [2:0]  mem_size_o,
  output logic        mem_req_o,
  output logic        mem_we_o,
  output logic [31:0] mem_wd_o
);
  import decoder_pkg::*;

  logic [31:0] pc, next_pc;
  logic [31:0] rd1, rd2, alu_a, alu_b, alu_res, wb_data;
  logic [31:0] imm_I, imm_U, imm_S, imm_B, imm_J, imm_Z;
  logic [1:0] a_sel, wb_sel;
  logic [2:0] b_sel, csr_op;
  logic [4:0] alu_op;
  logic gpr_we, csr_we, mem_req, mem_we, flag;
  logic branch, jal, jalr, mret, illegal_instr;
  logic trap, irq, exception, retire, mret_commit;
  logic [31:0] csr_wd, mie, mepc, mtvec, irq_cause, csr_mcause;

  assign imm_I = {{20{instr_i[31]}}, instr_i[31:20]};
  assign imm_U = {instr_i[31:12], 12'b0};
  assign imm_S = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
  assign imm_B = {{19{instr_i[31]}}, instr_i[31], instr_i[7],
                  instr_i[30:25], instr_i[11:8], 1'b0};
  assign imm_J = {{11{instr_i[31]}}, instr_i[31], instr_i[19:12],
                  instr_i[20], instr_i[30:21], 1'b0};
  assign imm_Z = {27'b0, instr_i[19:15]};

  assign exception = ENABLE_TRAPS && !rst_i && illegal_instr;
  assign trap = exception || irq;
  assign csr_mcause = exception ? 32'h0000_0002 : irq_cause;
  // A stalled or interrupted instruction must not modify GPRs or CSRs.
  assign retire = !rst_i && !stall_i && !trap && !illegal_instr;
  assign mret_commit = ENABLE_TRAPS && mret && !rst_i && !stall_i;

  always_ff @(posedge clk_i) begin
    if (rst_i)
      pc <= 32'b0;
    else if (!stall_i || trap)
      pc <= next_pc;
  end

  always_comb begin
    next_pc = pc + 32'd4;
    if (jal || (branch && flag))
      next_pc = pc + (branch ? imm_B : imm_J);
    if (jalr)
      next_pc = (rd1 + imm_I) & 32'hffff_fffe;
    if (trap)
      next_pc = mtvec;
    if (mret_commit)
      next_pc = mepc;
  end

  always_comb begin
    case (a_sel)
      OP_A_RS1:     alu_a = rd1;
      OP_A_CURR_PC: alu_a = pc;
      OP_A_ZERO:    alu_a = 32'b0;
      default:      alu_a = 32'b0;
    endcase
    case (b_sel)
      OP_B_RS2:   alu_b = rd2;
      OP_B_IMM_I: alu_b = imm_I;
      OP_B_IMM_U: alu_b = imm_U;
      OP_B_IMM_S: alu_b = imm_S;
      OP_B_INCR:  alu_b = 32'd4;
      default:    alu_b = 32'b0;
    endcase
    case (wb_sel)
      WB_EX_RESULT: wb_data = alu_res;
      WB_LSU_DATA:  wb_data = mem_rd_i;
      WB_CSR_DATA:  wb_data = csr_wd;
      default:      wb_data = 32'b0;
    endcase
  end

  assign instr_addr_o = pc;
  assign mem_addr_o = alu_res;
  assign mem_wd_o = rd2;
  assign mem_req_o = mem_req && !rst_i && !trap && !illegal_instr;
  assign mem_we_o = mem_we && !rst_i && !trap && !illegal_instr;

  register_file register_file (
    .clk_i(clk_i),
    .write_enable_i(gpr_we && retire),
    .write_addr_i(instr_i[11:7]),
    .read_addr1_i(instr_i[19:15]), .read_addr2_i(instr_i[24:20]),
    .write_data_i(wb_data), .read_data1_o(rd1), .read_data2_o(rd2)
  );

  alu alu (
    .a_i(alu_a), .b_i(alu_b), .alu_op_i(alu_op),
    .flag_o(flag), .result_o(alu_res)
  );

  decoder decoder (
    .fetched_instr_i(instr_i),
    .a_sel_o(a_sel), .b_sel_o(b_sel), .alu_op_o(alu_op),
    .csr_op_o(csr_op), .csr_we_o(csr_we),
    .mem_req_o(mem_req), .mem_we_o(mem_we), .mem_size_o(mem_size_o),
    .gpr_we_o(gpr_we), .wb_sel_o(wb_sel),
    .illegal_instr_o(illegal_instr), .branch_o(branch),
    .jal_o(jal), .jalr_o(jalr), .mret_o(mret)
  );

  csr_controller csr_controller (
    .clk_i(clk_i), .rst_i(rst_i), .trap_i(trap),
    .opcode_i(csr_op), .addr_i(instr_i[31:20]),
    .pc_i(pc), .mcause_i(csr_mcause),
    .rs1_data_i(rd1), .imm_data_i(imm_Z),
    .write_enable_i(csr_we && retire),
    .read_data_o(csr_wd), .mie_o(mie), .mepc_o(mepc), .mtvec_o(mtvec)
  );

  interrupt_controller interrupt_controller (
    .clk_i(clk_i), .rst_i(rst_i), .exception_i(exception),
    .irq_req_i(ENABLE_TRAPS && !rst_i && irq_req_i),
    .mie_i(mie[16]), .mret_i(mret_commit),
    .irq_ret_o(irq_ret_o), .irq_cause_o(irq_cause), .irq_o(irq)
  );
endmodule
