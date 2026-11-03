`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.05.2026 20:28:04
// Design Name: 
// Module Name: led_sb_ctrl
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


module led_sb_ctrl(
/*
    Часть интерфейса модуля, отвечающая за подключение к системной шине
*/
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        req_i,
  input  logic        write_enable_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] write_data_i,
  output logic [31:0] read_data_o,

/*
    Часть интерфейса модуля, отвечающая за подключение к периферии
*/
  output logic [15:0] led_o
);

logic [15:0]  led_val;
logic         led_mode;

always_ff @(posedge clk_i) begin
    if(addr_i == 'h00 & req_i == 1) begin
        if (write_enable_i == 1) begin
            led_val <= write_data_i[15:0];
        end
        else if (write_enable_i == 0) begin
            read_data_o <= {16'd0, led_val};
        end
    end
    
    if(addr_i == 'h04 & req_i == 1) begin
        if (write_enable_i == 1) begin
            led_mode <= write_data_i[0];
        end
        else if (write_enable_i == 0) begin
            read_data_o <= {31'd0, led_mode};
        end
    end
    
    if ((addr_i == 'h24 & req_i == 1 & write_enable_i == 1 & write_data_i == 1) | rst_i == 1) begin
        led_val <= 0;
        led_mode <= 0;
    end
end

logic [31:0] counter;

always_ff @(posedge clk_i) begin
    if (counter == 32'd19_999_999) begin
        counter <= 32'd0;
    end
    else if(rst_i == 1) begin
        counter <= 0;
    end
    else begin
        counter <= counter + 1'b1;
    end
end

always_ff @(posedge clk_i) begin
    if (counter < 32'd10_000_000 & led_mode == 1) begin
        led_o <= 16'd0;
    end
    else begin
        led_o <= led_val;
    end
end

endmodule