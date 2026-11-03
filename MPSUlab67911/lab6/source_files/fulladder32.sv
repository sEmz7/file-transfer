`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.04.2026 13:55:21
// Design Name: 
// Module Name: fulladder32
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


module fulladder32(
    input [31:0] a_i,
    input [31:0] b_i,
    input carry_i,
    output [31:0] sum_o,
    output carry_o
    );
    
    logic [6:0] carry;
    
    fulladder4 fulladder4_0(
        .a_i(a_i[3:0]),
        .b_i(b_i[3:0]),
        .carry_i(carry_i),
        .sum_o(sum_o[3:0]),
        .carry_o(carry[0])
    );
    
    fulladder4 fulladder4_1(
        .a_i(a_i[7:4]),
        .b_i(b_i[7:4]),
        .carry_i(carry[0]),
        .sum_o(sum_o[7:4]),
        .carry_o(carry[1])
    );
    
    fulladder4 fulladder4_2(
        .a_i(a_i[11:8]),
        .b_i(b_i[11:8]),
        .carry_i(carry[1]),
        .sum_o(sum_o[11:8]),
        .carry_o(carry[2])
    );
    
    fulladder4 fulladder4_3(
        .a_i(a_i[15:12]),
        .b_i(b_i[15:12]),
        .carry_i(carry[2]),
        .sum_o(sum_o[15:12]),
        .carry_o(carry[3])
    );
    
    fulladder4 fulladder4_4(
        .a_i(a_i[19:16]),
        .b_i(b_i[19:16]),
        .carry_i(carry[3]),
        .sum_o(sum_o[19:16]),
        .carry_o(carry[4])
    );
    
    fulladder4 fulladder4_5(
        .a_i(a_i[23:20]),
        .b_i(b_i[23:20]),
        .carry_i(carry[4]),
        .sum_o(sum_o[23:20]),
        .carry_o(carry[5])
    );
    
    fulladder4 fulladder4_6(
        .a_i(a_i[27:24]),
        .b_i(b_i[27:24]),
        .carry_i(carry[5]),
        .sum_o(sum_o[27:24]),
        .carry_o(carry[6])
    );
    
    fulladder4 fulladder4_7(
        .a_i(a_i[31:28]),
        .b_i(b_i[31:28]),
        .carry_i(carry[6]),
        .sum_o(sum_o[31:28]),
        .carry_o(carry_o)
    );
    
endmodule
