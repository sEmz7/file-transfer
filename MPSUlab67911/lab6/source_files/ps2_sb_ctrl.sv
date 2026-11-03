`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.05.2026 20:00:06
// Design Name: 
// Module Name: ps2_sb_ctrl
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


module ps2_sb_ctrl(
/*
    Часть интерфейса модуля, отвечающая за подключение к системной шине
*/
  input  logic         clk_i,
  input  logic         rst_i,
  input  logic [31:0]  addr_i,
  input  logic         req_i,
  input  logic [31:0]  write_data_i,
  input  logic         write_enable_i,
  output logic [31:0]  read_data_o,

/*
    Часть интерфейса модуля, отвечающая за отправку запросов на прерывание
    процессорного ядра
*/

  output logic        interrupt_request_o,
  input  logic        interrupt_return_i,

/*
    Часть интерфейса модуля, отвечающая за подключение к модулю,
    осуществляющему приём данных с клавиатуры
*/
  input  logic kclk_i,
  input  logic kdata_i
);

logic [7:0] scan_code;
logic       scan_code_is_unread;

logic [7:0] key_code;
logic keycode_valid;

PS2Receiver PS2Receiver(
    .clk_i(clk_i),          // Сигнал тактирования
    .rst_i(rst_i),          // Сигнал сброса
    .kclk_i(kclk_i),         // Тактовый сигнал, приходящий с клавиатуры
    .kdata_i(kdata_i),        // Сигнал данных, приходящий с клавиатуры
    .keycode_o(key_code),      // Сигнал полученного с клавиатуры скан-кода клавиши
    .keycode_valid_o(keycode_valid) // Сигнал готовности данных на выходе keycodeout
);

always_ff @(posedge clk_i) begin
   if (keycode_valid == 1) begin
    scan_code <= key_code;
    scan_code_is_unread <= 1;
   end
   if (addr_i == 'h00 & write_enable_i == 0 & req_i == 1) begin //rd
    read_data_o <= {24'd0, scan_code};
    if (keycode_valid == 0) begin
        scan_code_is_unread <= 0;
    end
   end
   if (interrupt_return_i == 1 & keycode_valid == 0) begin
    scan_code_is_unread <= 0;
   end
   if (addr_i == 'h04 & write_enable_i == 0 & req_i == 1) begin //rd
    read_data_o <= {31'd0, scan_code_is_unread};
   end
   if ((addr_i == 'h24 & write_enable_i == 1 & req_i == 1 & write_data_i == 1) | rst_i == 1) begin //wd
    scan_code <= 0;
    scan_code_is_unread <= 0;
   end
end

assign interrupt_request_o = scan_code_is_unread;

endmodule