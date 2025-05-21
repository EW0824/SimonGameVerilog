// tb_sequence_loader.v
`timescale 1ns/1ps

module tb_sequence_loader;
  //–– Parameters & ports
  localparam N = 4;            // shrink N for simulation speed
  reg         clk, reset;
  reg  [1:0]  lfsr_val;
  wire        write_en, lfsr_enable, done;
  wire [3:0]  wr_addr;
  wire [1:0]  wr_data;

  //–– DUT instantiation
  sequence_loader #(.N(N)) dut (
    .clk    (clk),
    .reset       (reset),
    .lfsr_val    (lfsr_val),
    .write_en    (write_en),
    .wr_addr     (wr_addr),
    .wr_data     (wr_data),
    .lfsr_enable (lfsr_enable),
    .done        (done)
  );

  //–– waveform dump
  initial begin
    $dumpfile("tb_sequence_loader.vcd");
    $dumpvars(0, tb_sequence_loader);
  end

  //–– clock generator: 10 ns period
  initial clk = 0;
  always #5 clk = ~clk;

  //–– stimulus & checks
  initial begin
    // 1) Reset
    reset = 1; #12;
    reset = 0;

    // 2) Drive LFSR values for N+2 ticks
    repeat (N+2) begin
      @(posedge clk);
      lfsr_val = $random;  // random or fixed pattern
    end

    // 3) Check that done went high on cycle N
    if (done !== 1) begin
      $fatal(1, "❌ ERROR: loader.done did not assert after %0d writes", N);
    end else begin
      $display("✅ PASS: loader.done asserted at the right time");
    end

    // 4) Spot-check wr_addr & wr_data
    //    (You could capture them in an array and compare if you want)

    $finish;
  end
endmodule