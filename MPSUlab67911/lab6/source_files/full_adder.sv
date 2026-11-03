`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.04.2026 13:33:13
// Design Name: 
// Module Name: full_adder
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


module fulladder(
    input a_i,
    input b_i,
    input carry_i,
    output sum_o,
    output carry_o
    );
    logic AxorB;
    logic AxorBxorCarry;
    logic AandB;
    logic AandCarry;
    logic AandBorAandCarry;
    logic BandCarry;
    
    assign AxorB = a_i ^ b_i;
    assign AandB = a_i & b_i;
    assign AandCarry = a_i & carry_i;
    assign BandCarry = b_i & carry_i;
    assign AxorBxorCarry = AxorB ^ carry_i;
    assign AandBorAandCarry = AandB | AandCarry;
    
    assign sum_o = AxorBxorCarry;
    assign carry_o = AandBorAandCarry | BandCarry;
    
endmodule
