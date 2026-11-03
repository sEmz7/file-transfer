`timescale 1ns / 1ps

// Self-checking tests supplement the upstream waveform demonstrations.
module tb_lab6;
  logic clk = 0;
  always #5 clk = ~clk;
  logic rst = 1, checkpoint_rst = 1;
  processor_system DUT (.clk_i(clk), .rst_i(rst));
  processor_system #(.ENABLE_TRAPS(1'b0)) CHECKPOINT (
    .clk_i(clk), .rst_i(checkpoint_rst)
  );

  logic hold_rst = 1, hold_stall = 0;
  logic [31:0] hold_instr = 32'h00000013;
  processor_core HOLD (
    .clk_i(clk), .rst_i(hold_rst), .stall_i(hold_stall),
    .irq_req_i(1'b0), .instr_i(hold_instr), .mem_rd_i(32'b0),
    .irq_ret_o(), .instr_addr_o(), .mem_addr_o(), .mem_size_o(),
    .mem_req_o(), .mem_we_o(), .mem_wd_o()
  );

  int checks = 0;
  logic test_passed = 0;
  int exceptions = 0, interrupts = 0;
  always @(posedge clk) begin
    if (rst) begin
      exceptions <= 0;
      interrupts <= 0;
    end else begin
      if (DUT.core.exception) exceptions <= exceptions + 1;
      if (DUT.core.irq) interrupts <= interrupts + 1;
    end
  end

  task automatic tick;
    @(posedge clk);
    #1;
  endtask

  task automatic check32(input logic [31:0] actual, expected, input string name);
    checks++;
    if (actual !== expected)
      $fatal(1, "%s: got %08h, expected %08h", name, actual, expected);
  endtask

  task automatic check_reg(input int address, input logic [31:0] expected);
    check32(DUT.core.register_file.rf_mem[address], expected,
            $sformatf("x%0d", address));
  endtask

  task automatic reset_main(input string image);
    rst = 1;
    DUT.irq_req = 0;
    for (int i = 0; i < 128; i++) DUT.instr_mem.ROM[i] = 32'h00000013;
    $readmemh(image, DUT.instr_mem.ROM);
    repeat (3) tick();
    check32(DUT.instr_addr, 0, "PC after reset");
    rst = 0;
  endtask

  task automatic wait_pc(input logic [31:0] target, input int limit = 500);
    int cycles;
    cycles = 0;
    while (DUT.instr_addr !== target && cycles < limit) begin
      tick();
      cycles++;
    end
    check32(DUT.instr_addr, target, "PC/watchdog");
  endtask

  task automatic wait_irq_return;
    int cycles;
    cycles = 0;
    while (DUT.irq_ret !== 1'b1 && cycles < 500) begin
      tick();
      cycles++;
    end
    check32({31'b0, DUT.irq_ret}, 1, "interrupt return/watchdog");
    // Release the source before MRET commits, so it cannot retrigger.
    DUT.irq_req = 0;
    tick();
  endtask

  task automatic individual_case(input logic [31:0] value, expected);
    reset_main("individual.mem");
    // Change only the input constant; the algorithm is identical in all cases.
    DUT.instr_mem.ROM[0] = ((value + 32'h800) & 32'hfffff000) | 32'h000000b7;
    DUT.instr_mem.ROM[1] = {value[11:0], 20'h08093};
    wait_pc(32'h34);
    check_reg(10, expected);
    check32(DUT.data_mem.ram[0], expected, "individual result in RAM");
    check32(exceptions, 0, "individual: no exceptions");
  endtask

  initial begin
    if ($test$plusargs("waves")) begin
      $dumpfile("lab6.vcd");
      $dumpvars(0, tb_lab6);
    end
    repeat (3) tick();

    $display("TEST lab 7/9: original datapath program and subword memory");
    for (int i = 0; i < 128; i++) CHECKPOINT.instr_mem.ROM[i] = 32'h00000013;
    $readmemh("lab07.mem", CHECKPOINT.instr_mem.ROM);
    checkpoint_rst = 0;
    repeat (100) tick();
    check32(CHECKPOINT.instr_addr, 'h64, "lab07 terminal JALR");
    check32(CHECKPOINT.core.register_file.rf_mem[3], 3, "lab07 ADD");
    check32(CHECKPOINT.core.register_file.rf_mem[4], 4, "lab07 AND");
    check32(CHECKPOINT.core.register_file.rf_mem[5], 1, "lab07 SUB");
    check32(CHECKPOINT.core.register_file.rf_mem[7], 'h80000000, "lab07 SLLI");
    check32(CHECKPOINT.core.register_file.rf_mem[8], 'hc0000000, "lab07 SRAI");
    check32(CHECKPOINT.core.register_file.rf_mem[9], 6, "lab07 SRLI");
    check32(CHECKPOINT.core.register_file.rf_mem[10], 'hfadebabe, "lab07 LUI/ADDI");
    check32(CHECKPOINT.core.register_file.rf_mem[11], 'hfadebabe, "lab09 LW");
    check32(CHECKPOINT.core.register_file.rf_mem[12], 'hffffbabe, "lab09 LH");
    check32(CHECKPOINT.core.register_file.rf_mem[13], 'hffffffbe, "lab09 LB");
    check32(CHECKPOINT.core.register_file.rf_mem[14], 'h68, "lab07 JALR link");
    check32(CHECKPOINT.core.register_file.rf_mem[15], 'hbe, "lab09 LBU");
    check32(CHECKPOINT.core.register_file.rf_mem[16], 'h4054, "lab07 AUIPC");
    check32(CHECKPOINT.core.register_file.rf_mem[17], 'h64, "lab07 JAL link");
    check32(CHECKPOINT.core.register_file.rf_mem[18], 'h6c, "lab07 initial JALR link");
    check32(CHECKPOINT.data_mem.ram[1], 'hfadebabe, "lab09 SW");
    check32({16'b0, CHECKPOINT.data_mem.ram[2][31:16]}, 'hbabe, "lab09 SH lane");
    check32({24'b0, CHECKPOINT.data_mem.ram[3][31:24]}, 'hbe, "lab09 SB lane");
    checkpoint_rst = 1;

    $display("TEST lab 11: exception, pending IRQ, handler and MRET");
    reset_main("lab11.mem");
    repeat (20) tick();
    DUT.irq_req = 1;
    wait_irq_return();
    repeat (40) tick();
    check32(DUT.instr_addr, 'h34, "lab11 returns to main");
    check32(DUT.data_mem.ram[0], 4, "lab11 global: 1 + 3");
    check_reg(2, 'h1f0);
    check_reg(6, 0);
    check_reg(7, 0);
    check32(DUT.core.csr_controller.mscratch, 'hf0, "handler stack restored");
    check32(DUT.core.mepc, 'h34, "saved IRQ PC");
    check32(DUT.core.csr_controller.mcause, 'h80000010, "IRQ cause");
    check32(exceptions, 1, "one ECALL exception");
    check32(interrupts, 1, "one external interrupt");

    $display("TEST interrupted CSR instruction has no premature side effects");
    reset_main("csr_irq.mem");
    wait_pc('h18);
    DUT.irq_req = 1;
    tick();
    check32(DUT.instr_addr, 'h60, "IRQ vector");
    check32(DUT.core.csr_controller.mscratch, 5, "interrupted CSR stays unchanged");
    wait_irq_return();
    wait_pc('h20);
    check_reg(4, 5);
    check_reg(5, 9);
    check_reg(20, 5);
    check_reg(21, 'h80000010);
    check32(DUT.core.csr_controller.mscratch, 9, "CSR reexecutes after MRET");
    check32(interrupts, 1, "CSR interruption occurs once");

    $display("TEST signed/unsigned loads, partial stores and dependent loads");
    reset_main("memory.mem");
    wait_pc('h60);
    check_reg(2, 1);
    check_reg(3, 'h7f);
    check_reg(4, 'hffffffff);
    check_reg(5, 'hffffff80);
    check_reg(6, 'hff);
    check_reg(7, 'h80);
    check_reg(8, 'h7f01);
    check_reg(9, 'hffff80ff);
    check_reg(10, 'h80ff);
    check_reg(11, 'h80ff7f01);
    check_reg(13, 'hffffa501);
    check_reg(14, 'hffffa501);
    check_reg(15, 42);
    check_reg(16, 43);
    check32(DUT.data_mem.ram[0], 'hffffa501, "untouched store lanes");
    check32(exceptions, 0, "memory program: no exceptions");

    $display("TEST RV32I arithmetic, six branches, backward jumps and JALR alignment");
    reset_main("rv32i.mem");
    wait_pc('hc8);
    check_reg(3, 'hfffffffb);
    check_reg(4, 11);
    check_reg(5, 0);
    check_reg(6, 'hfffffffb);
    check_reg(7, 'hfffffffb);
    check_reg(8, 24);
    check_reg(9, 'h1fffffff);
    check_reg(10, 'hffffffff);
    check_reg(11, 1);
    check_reg(12, 0);
    check_reg(13, 'h80000000);
    check_reg(14, 1);
    check_reg(15, 'hffffffff);
    check_reg(16, 7);
    check_reg(17, 'h55);
    check_reg(18, 8);
    check_reg(19, 1);
    check_reg(20, 0);
    check_reg(21, 'habcde000);
    check_reg(22, 'h1054);
    check_reg(23, 3);
    check_reg(24, 0);
    check_reg(25, 'ha8);
    check_reg(26, 'hb9);
    check_reg(27, 'hb8);
    check_reg(28, 'h123);
    check32(exceptions, 0, "RV32I program: no exceptions");

    $display("TEST individual variant 21, including zero/max/high-bit inputs");
    individual_case('h1230, 6);
    individual_case(0, 0);
    individual_case('hffff, 60);
    individual_case('h8000, 8);
    individual_case('hfedc, 54);
    individual_case('hdeadbeef, 54);

    $display("TEST CSR and PC remain unchanged while stalled");
    rst = 1;
    hold_instr = 32'h00500093; // addi x1, x0, 5
    hold_rst = 0;
    tick();
    hold_instr = 32'h34009073; // csrrw x0, mscratch, x1
    hold_stall = 1;
    repeat (3) tick();
    check32(HOLD.pc, 4, "stalled PC");
    check32(HOLD.csr_controller.mscratch, 0, "stalled CSR write");
    hold_stall = 0;
    tick();
    check32(HOLD.csr_controller.mscratch, 5, "resumed CSR write");
    hold_instr = 32'h3403d173; // csrrwi x2, mscratch, 7
    hold_stall = 1;
    repeat (3) tick();
    check32(HOLD.csr_controller.mscratch, 5, "stalled CSRRWI");
    hold_stall = 0;
    tick();
    check32(HOLD.register_file.rf_mem[2], 5, "CSR writeback uses old value");
    check32(HOLD.csr_controller.mscratch, 7, "CSRRWI commits once");

    test_passed = 1;
    $display("PASS tb_lab6: %0d checks", checks);
    $finish;
  end

  initial begin
    #200000;
    $fatal(1, "tb_lab6 watchdog expired");
  end
endmodule
