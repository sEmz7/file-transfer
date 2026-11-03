
module lsu(
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        core_req_i,
  input  logic        core_we_i,
  input  logic [2:0]  core_size_i,
  input  logic [31:0] core_addr_i,
  input  logic [31:0] core_wd_i,
  output logic [31:0] core_rd_o,
  output logic        core_stall_o,
  output logic        mem_req_o,
  output logic        mem_we_o,
  output logic [3:0]  mem_be_o,
  output logic [31:0] mem_addr_o,
  output logic [31:0] mem_wd_o,
  input  logic [31:0] mem_rd_i,
  input  logic        mem_ready_i
);

  import decoder_pkg::*;

  logic stall_reg;

    assign core_stall_o = core_req_i && (!mem_ready_i || !stall_reg);

    always_ff @(posedge clk_i) begin
    if (rst_i)
        stall_reg <= 1'b0;
    else
        stall_reg <= core_stall_o;
    end

  assign mem_req_o  = core_req_i;
  assign mem_we_o   = core_we_i;
  assign mem_addr_o = core_addr_i;

  // Select and extend the requested load value.
  always_comb begin
    core_rd_o = 32'b0;

    case (core_size_i)
      LDST_B: begin
        case (core_addr_i[1:0])
          2'd0: core_rd_o = {{24{mem_rd_i[7]}},  mem_rd_i[7:0]};
          2'd1: core_rd_o = {{24{mem_rd_i[15]}}, mem_rd_i[15:8]};
          2'd2: core_rd_o = {{24{mem_rd_i[23]}}, mem_rd_i[23:16]};
          2'd3: core_rd_o = {{24{mem_rd_i[31]}}, mem_rd_i[31:24]};
        endcase
      end

      LDST_BU: begin
        case (core_addr_i[1:0])
          2'd0: core_rd_o = {24'b0, mem_rd_i[7:0]};
          2'd1: core_rd_o = {24'b0, mem_rd_i[15:8]};
          2'd2: core_rd_o = {24'b0, mem_rd_i[23:16]};
          2'd3: core_rd_o = {24'b0, mem_rd_i[31:24]};
        endcase
      end

      LDST_H: begin
        if (core_addr_i[1])
          core_rd_o = {{16{mem_rd_i[31]}}, mem_rd_i[31:16]};
        else
          core_rd_o = {{16{mem_rd_i[15]}}, mem_rd_i[15:0]};
      end

      LDST_HU: begin
        if (core_addr_i[1])
          core_rd_o = {16'b0, mem_rd_i[31:16]};
        else
          core_rd_o = {16'b0, mem_rd_i[15:0]};
      end

      LDST_W: core_rd_o = mem_rd_i;

      default: core_rd_o = 32'b0;
    endcase
  end

  // Select byte lanes for stores.
  always_comb begin
    case (core_size_i)
      LDST_B: begin
        case (core_addr_i[1:0])
          2'd0: mem_be_o = 4'b0001;
          2'd1: mem_be_o = 4'b0010;
          2'd2: mem_be_o = 4'b0100;
          2'd3: mem_be_o = 4'b1000;
          default: mem_be_o = 4'b0000;
        endcase
      end

      LDST_H: begin
        if (core_addr_i[1])
          mem_be_o = 4'b1100;
        else
          mem_be_o = 4'b0011;
      end

      LDST_W:  mem_be_o = 4'b1111;
      default: mem_be_o = 4'b0000;
    endcase
  end

  // Replicate store data across the word; byte enables select active lanes.
  always_comb begin
    case (core_size_i)
      LDST_B: mem_wd_o = {4{core_wd_i[7:0]}};
      LDST_H: mem_wd_o = {2{core_wd_i[15:0]}};
      LDST_W: mem_wd_o = core_wd_i;
      default: mem_wd_o = 32'b0;
    endcase
  end

endmodule
