`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.05.2026 17:51:47
// Design Name: 
// Module Name: register_file
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


module register_file(
    input clk_i,
    input write_enable_i,
    
    input [4:0] write_addr_i,
    input [4:0] read_addr1_i,
    input [4:0] read_addr2_i,
    
    input [31:0] write_data_i,
    output [31:0] read_data1_o,
    output [31:0] read_data2_o
    );
    
    logic [31:0] rf_mem [31:0];


    assign read_data1_o = read_addr1_i == 0 ? 0 : rf_mem[read_addr1_i];
    
    assign read_data2_o = read_addr2_i == 0 ? 0 : rf_mem[read_addr2_i];

    always_ff @(posedge clk_i) begin
        if(write_enable_i && write_addr_i != 5'd0) begin
            rf_mem[write_addr_i] <= write_data_i;
        end
     end
endmodule
