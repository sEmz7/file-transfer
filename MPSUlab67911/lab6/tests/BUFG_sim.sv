`timescale 1ns / 1ps
// Used only by the local board-wrapper lint check, never by synthesis.
module BUFG(input wire I, output wire O);
  assign O = I;
endmodule
