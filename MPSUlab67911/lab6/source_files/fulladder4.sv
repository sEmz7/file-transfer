`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.04.2026 13:56:56
// Design Name: 
// Module Name: fulladder4
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


module fulladder4(
    input [3:0] a_i,
    input [3:0] b_i,
    input carry_i,
    output [3:0] sum_o,
    output carry_o
    );
    
    logic carry_0, carry_1, carry_2;
    
    
    fulladder fulladder_0(
        .a_i(a_i[0]),
        .b_i(b_i[0]),
        .carry_i(carry_i),
        .sum_o(sum_o[0]),
        .carry_o(carry_0)
    );
    
        
    fulladder fulladder_1(
        .a_i(a_i[1]),
        .b_i(b_i[1]),
        .carry_i(carry_0),
        .sum_o(sum_o[1]),
        .carry_o(carry_1)
    );
        
    fulladder fulladder_2(
        .a_i(a_i[2]),
        .b_i(b_i[2]),
        .carry_i(carry_1),
        .sum_o(sum_o[2]),
        .carry_o(carry_2)
    );
        
    fulladder fulladder_3(
        .a_i(a_i[3]),
        .b_i(b_i[3]),
        .carry_i(carry_2),
        .sum_o(sum_o[3]),
        .carry_o(carry_o)
    );
    
    
endmodule
