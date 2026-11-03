`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.04.2026 15:20:05
// Design Name: 
// Module Name: alu
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


module alu(
    input [31:0] a_i,
    input [31:0] b_i,
    input [4:0] alu_op_i,
    output flag_o,
    output [31:0] result_o
    );
    
    import alu_opcodes_pkg::*;
        
    logic Flag;
    always_comb begin
        case(alu_op_i)
            ALU_EQ: Flag = a_i == b_i;
            ALU_NE: Flag = a_i != b_i;
            ALU_LTS: Flag = $signed(a_i) < $signed(b_i);
            ALU_GES: Flag = $signed(a_i) >= $signed(b_i);
            ALU_LTU: Flag = a_i < b_i;
            ALU_GEU: Flag = a_i >= b_i;
            default: Flag = 0;
        endcase
    end
    assign flag_o = Flag;

    logic [31:0] sum;
    logic unused_carry;

    fulladder32 fulladder32(
        .a_i(a_i),
        .b_i(b_i),
        .carry_i(1'b0),
        .sum_o(sum),
        .carry_o(unused_carry)
    );
    
    logic [31:0] Result;
    always_comb begin
        case(alu_op_i)
            ALU_ADD: Result = sum;
            ALU_SUB: Result = a_i - b_i;
            ALU_SLL : Result = a_i << b_i[4:0];
            ALU_SLTS: Result = {31'b0, $signed(a_i) < $signed(b_i)};
            ALU_SLTU: Result = {31'b0, a_i < b_i};
            ALU_XOR: Result = a_i ^ b_i;
            ALU_SRL: Result = a_i >> b_i[4:0];  
            ALU_SRA: Result = $signed(a_i) >>> b_i[4:0];
            ALU_OR: Result = a_i | b_i;
            ALU_AND: Result = a_i & b_i;
            default: Result = 0;
        endcase
    end
    assign result_o = Result;
endmodule
