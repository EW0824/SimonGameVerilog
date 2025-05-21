// tb_sequence_rom.v
`timescale 1ns/1ps

module tb_sequence_rom;
  // parameterize depth down for fast sim
  localparam DEPTH = 4;

  // DUT ports
  reg          clk, write_en;
  reg  [3:0]   wr_addr, rd_addr;
  reg  [1:0]   wr_data;
  wire [1:0]   rd_data;

  // instantiate your ROM
  sequence_rom #(.DEPTH(DEPTH)) dut (
    .clk      (clk),
    .write_en (write_en),
    .wr_addr  (wr_addr),
    .wr_data  (wr_data),
    .rd_addr  (rd_addr),
    .rd_data  (rd_data)
  );

  // waveform dump
  initial begin
    $dumpfile("tb_sequence_rom.vcd");
    $dumpvars(0, tb_sequence_rom);
  end

  // 10 ns clock
  initial clk = 0;
  always #5 clk = ~clk;

  integer i;
  initial begin
    // 1) Write phase
    write_en = 1;
    for (i = 0; i < DEPTH; i = i + 1) begin
      wr_addr = i;
      wr_data = i[1:0];
      @(posedge clk);
    end
    write_en = 0;

    // small pause
    #10;

    // 2) Read phase & checking
    for (i = 0; i < DEPTH; i = i + 1) begin
      rd_addr = i;
      @(posedge clk);
      if (rd_data !== i[1:0]) begin
        $fatal(1, "❌ ROM mismatch at addr %0d: got %b, expected %b", i, rd_data, i[1:0]);
      end else begin
        $display("Addr %0d → %b (OK)", i, rd_data);
      end
    end

    $display("✅ PASS: sequence_rom read/write works for DEPTH=%0d", DEPTH);
    $finish;
  end
endmodule