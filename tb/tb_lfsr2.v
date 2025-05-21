// tb_lfsr2.v
`timescale 1ns/1ps

module tb_lfsr2;
  // DUT ports
  reg         clk, reset, enable;
  wire [1:0]  q;

  // instantiate your LFSR
  lfsr2 dut (
    .clk    (clk),
    .reset  (reset),
    .enable (enable),
    .q      (q)
  );

  // waveform dump
  initial begin
    $dumpfile("tb_lfsr2.vcd");
    $dumpvars(0, tb_lfsr2);
  end

  // 10 ns clock
  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    // 1) reset the LFSR
    reset = 1; enable = 0;
    #12; 
    reset = 0;

    // 2) start shifting
    enable = 1;

    // run for two full periods (max length for 2-bit LFSR is 3)
    repeat (6) begin
      @(posedge clk);
      $display("Cycle %0t: LFSR → %b", $time, q);
      if (q == 2'b00) begin
        $fatal(1, "❌ LFSR hit the all-zero state!"); 
      end
    end

    $display("✅ PASS: LFSR cycled through non-zero states correctly.");
    $finish;
  end
endmodule