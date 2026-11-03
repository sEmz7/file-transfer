`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.05.2026 15:52:27
// Design Name: 
// Module Name: decoder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module decoder (
  input  logic [31:0]  fetched_instr_i,
  output logic [1:0]   a_sel_o,
  output logic [2:0]   b_sel_o,
  output logic [4:0]   alu_op_o,
  output logic [2:0]   csr_op_o,
  output logic         csr_we_o,
  output logic         mem_req_o,
  output logic         mem_we_o,
  output logic [2:0]   mem_size_o,
  output logic         gpr_we_o,
  output logic [1:0]   wb_sel_o,
  output logic         illegal_instr_o,
  output logic         branch_o,
  output logic         jal_o,
  output logic         jalr_o,
  output logic         mret_o
);
  import decoder_pkg::*;
  
  logic [6:0] func7;
  assign func7 = fetched_instr_i[31:25];
  logic [2:0] func3;
  assign func3 = fetched_instr_i[14:12];
  logic [6:0] opcode;
  assign opcode = fetched_instr_i[6:0];
  
  always_comb begin
    a_sel_o = 2'd0;
    b_sel_o = 3'd0;
    alu_op_o = 5'd0;
    csr_op_o = 3'd0;
    csr_we_o = 1'b0;
    mem_req_o = 1'b0;
    mem_we_o = 1'b0;
    mem_size_o = 3'd0;
    gpr_we_o = 1'b0;
    wb_sel_o = 2'd0;
    illegal_instr_o = 1'b0;
    branch_o = 1'b0;
    jal_o = 1'b0;
    jalr_o = 1'b0;
    mret_o = 1'b0;
    if(opcode[1:0] != 2'b11) begin
        illegal_instr_o = 1'b1;
    end
    else begin
        case(opcode[6:2])
            OP_OPCODE: begin
                a_sel_o = OP_A_RS1;
                b_sel_o = OP_B_RS2;
                gpr_we_o = 1'b1;
                wb_sel_o = WB_EX_RESULT;
                case(func3)
                    3'h0: begin
                        case(func7)
                            7'h00: begin
                                alu_op_o = ALU_ADD;
                            end
                            7'h20: begin
                                alu_op_o = ALU_SUB;
                            end
                            default: begin
                                illegal_instr_o = 1'b1;
                            end
                        endcase
                    end
                    3'h4: begin
                        case(func7)
                            7'h00: begin
                                alu_op_o = ALU_XOR;
                            end
                            default: begin
                                illegal_instr_o = 1'b1;
                            end
                        endcase
                    end
                    3'h6: begin
                        case(func7)
                            7'h00: begin
                                alu_op_o = ALU_OR;
                            end
                            default: begin
                                illegal_instr_o = 1'b1;
                            end
                        endcase
                    end
                    3'h7: begin
                        case(func7)
                            7'h00: begin
                                alu_op_o = ALU_AND;
                            end
                            default: begin
                                illegal_instr_o = 1'b1;
                            end
                        endcase
                    end
                    3'h1: begin
                        case(func7)
                            7'h00: begin
                                alu_op_o = ALU_SLL;
                            end
                            default: begin
                                illegal_instr_o = 1'b1;
                            end
                        endcase
                    end
                    3'h5: begin
                        case(func7)
                            7'h00: begin
                                alu_op_o = ALU_SRL;
                            end
                            7'h20: begin
                                alu_op_o = ALU_SRA;
                            end
                            default: begin
                                illegal_instr_o = 1'b1;
                            end
                        endcase
                    end
                    3'h2: begin
                        case(func7)
                            7'h00: begin
                                alu_op_o = ALU_SLTS;
                            end
                            default: begin
                                illegal_instr_o = 1'b1;
                            end
                        endcase
                    end
                    3'h3: begin
                        case(func7)
                            7'h00: begin
                                alu_op_o = ALU_SLTU;
                            end
                            default: begin
                                illegal_instr_o = 1'b1;
                            end
                        endcase
                    end
                    default: begin
                        illegal_instr_o = 1'b1;
                    end
                endcase
            end
            OP_IMM_OPCODE: begin
                a_sel_o = OP_A_RS1;
                b_sel_o = OP_B_IMM_I;
                gpr_we_o = 1'b1;
                wb_sel_o = WB_EX_RESULT;
                case(func3)
                    3'h0: begin
                        alu_op_o = ALU_ADD;
                    end
                    3'h4: begin
                        alu_op_o = ALU_XOR;
                    end
                    3'h6: begin
                        alu_op_o = ALU_OR;
                    end
                    3'h7: begin
                        alu_op_o = ALU_AND;
                    end
                    3'h1: begin
                        case(func7)
                            7'h00: begin
                                alu_op_o = ALU_SLL;
                            end
                            default: begin
                                illegal_instr_o = 1'b1;
                            end
                        endcase
                    end
                    3'h5: begin
                        case(func7)
                            7'h00: begin
                                alu_op_o = ALU_SRL;
                            end
                            7'h20: begin
                                alu_op_o = ALU_SRA;
                            end
                            default: begin
                                illegal_instr_o = 1'b1;
                            end
                        endcase
                    end
                    3'h2: begin
                        alu_op_o = ALU_SLTS;
                    end
                    3'h3: begin
                        alu_op_o = ALU_SLTU;
                    end
                    default: begin
                        illegal_instr_o = 1'b1;
                    end
                endcase
            end
            LUI_OPCODE: begin
                a_sel_o = OP_A_ZERO;
                b_sel_o = OP_B_IMM_U;
                alu_op_o = ALU_ADD;
                gpr_we_o = 1'b1;
                wb_sel_o = WB_EX_RESULT;
            end
            LOAD_OPCODE: begin
                a_sel_o = OP_A_RS1;
                b_sel_o = OP_B_IMM_I;
                alu_op_o = ALU_ADD;
                gpr_we_o = 1'b1;
                wb_sel_o = WB_LSU_DATA;
                mem_we_o = 1'b0;
                mem_req_o = 1'b1;
                case(func3)
                    3'h0: begin
                        mem_size_o = LDST_B;
                    end
                    3'h1: begin
                        mem_size_o = LDST_H;
                    end
                    3'h2: begin
                        mem_size_o = LDST_W;
                    end
                    3'h4: begin
                        mem_size_o = LDST_BU;
                    end
                    3'h5: begin
                        mem_size_o = LDST_HU;
                    end
                    default: begin
                        illegal_instr_o = 1'b1;
                    end
                endcase
            end
            STORE_OPCODE: begin
                a_sel_o = OP_A_RS1;
                b_sel_o = OP_B_IMM_S;
                alu_op_o = ALU_ADD;
                gpr_we_o = 1'b0;
                wb_sel_o = WB_LSU_DATA;
                mem_we_o = 1'b1;
                mem_req_o = 1'b1;
                case(func3)
                    3'h0: begin
                        mem_size_o = LDST_B;
                    end
                    3'h1: begin
                        mem_size_o = LDST_H;
                    end
                    3'h2: begin
                        mem_size_o = LDST_W;
                    end
                    default: begin
                        illegal_instr_o = 1'b1;
                    end
                endcase
            end
            BRANCH_OPCODE: begin
                a_sel_o = OP_A_RS1;
                b_sel_o = OP_B_RS2;
                gpr_we_o = 1'b0;
                branch_o = 1'b1;
                case(func3)
                    3'h0: begin
                        alu_op_o = ALU_EQ;
                    end
                    3'h1: begin
                        alu_op_o = ALU_NE;
                    end
                    3'h4: begin
                        alu_op_o = ALU_LTS;
                    end
                    3'h5: begin
                        alu_op_o = ALU_GES;
                    end
                    3'h6: begin
                        alu_op_o = ALU_LTU;
                    end
                    3'h7: begin
                        alu_op_o = ALU_GEU;
                    end
                    default: begin
                        illegal_instr_o = 1'b1;
                    end
                endcase
            end
            JAL_OPCODE: begin
                a_sel_o = OP_A_CURR_PC;
                b_sel_o = OP_B_INCR;
                alu_op_o = ALU_ADD;
                gpr_we_o = 1'b1;
                wb_sel_o = WB_EX_RESULT;
                jal_o = 1'b1;
            end
            JALR_OPCODE: begin
                if (func3 == 3'h0) begin
                    a_sel_o = OP_A_CURR_PC;
                    b_sel_o = OP_B_INCR;
                    alu_op_o = ALU_ADD;
                    gpr_we_o = 1'b1;
                    wb_sel_o = WB_EX_RESULT;
                    jalr_o = 1'b1;
                end
                else begin
                    illegal_instr_o = 1'b1;
                end
            end
            AUIPC_OPCODE: begin
                a_sel_o = OP_A_CURR_PC;
                b_sel_o = OP_B_IMM_U;
                alu_op_o = ALU_ADD;
                gpr_we_o = 1'b1;
                wb_sel_o = WB_EX_RESULT;
            end
            MISC_MEM_OPCODE: begin

            end
            SYSTEM_OPCODE: begin
                csr_we_o = 1'b0;
                gpr_we_o = 1'b0;
                wb_sel_o = WB_CSR_DATA;
                case(func3)
                    3'h0: begin
                    csr_we_o = 1'b0;
                    gpr_we_o = 1'b0;
                    wb_sel_o = 2'd0;
                        case(fetched_instr_i)
                            32'b00000000000000000000000001110011: begin
                                illegal_instr_o = 1'b1;
                            end
                            32'b00000000000100000000000001110011: begin
                                illegal_instr_o = 1'b1;
                            end
                            32'b00110000001000000000000001110011: begin
                                mret_o = 1'b1;
                            end
                            default: begin
                                illegal_instr_o = 1'b1;
                            end
                        endcase
                    end
                    3'h1: begin
                        csr_op_o = CSR_RW;
                        csr_we_o = 1'b1;
                        gpr_we_o = 1'b1;
                    end
                    3'h2: begin
                        csr_op_o = CSR_RS;
                        csr_we_o = 1'b1;
                        gpr_we_o = 1'b1;
                    end
                    3'h3: begin
                        csr_op_o = CSR_RC;
                        csr_we_o = 1'b1;
                        gpr_we_o = 1'b1;
                    end
                    3'h5: begin
                        csr_op_o = CSR_RWI;
                        csr_we_o = 1'b1;
                        gpr_we_o = 1'b1;
                    end
                    3'h6: begin
                        csr_op_o = CSR_RSI;
                        csr_we_o = 1'b1;
                        gpr_we_o = 1'b1;
                    end
                    3'h7: begin
                        csr_op_o = CSR_RCI;
                        csr_we_o = 1'b1;
                        gpr_we_o = 1'b1;
                    end
                    default: begin
                        illegal_instr_o = 1'b1;
                    end
                endcase
            end
            default: begin
                illegal_instr_o = 1'b1;
            end
        endcase
    end
  end

endmodule
