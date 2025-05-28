// tb_sequence_rom.v
`timescale 1ns/1ps

module tb_sequence_rom;
  // parameterize depth down for fast sim
  localparam DEPTH = 4;

  // DUT ports
  reg          clk_tb;
  reg          write_en_tb;
  reg  [3:0]   wr_addr_tb, rd_addr_tb;
  reg  [1:0]   wr_data_tb;
  wire [1:0]   rd_data_dut;

  // Enable debug output
  initial begin
    $display("TB: Starting simulation with DEPTH=%0d at time %0t", DEPTH, $time);
    $display("TB: Debug messages enabled at time %0t", $time);
  end

  // instantiate your ROM
  sequence_rom #(.DEPTH(DEPTH)) dut (
    .clk      (clk_tb),
    .write_en (write_en_tb),
    .wr_addr  (wr_addr_tb),
    .wr_data  (wr_data_tb),
    .rd_addr  (rd_addr_tb),
    .rd_data  (rd_data_dut)
  );

  // waveform dump
  initial begin
    $dumpfile("tb_sequence_rom.vcd");
    $dumpvars(0, tb_sequence_rom);
    $strobe("TB: VCD dump initialized at time %0t", $time);
  end

  // 10 ns clock
  initial begin
    clk_tb = 0;
    $strobe("TB: clk_tb initialized to 0 at time %0t", $time);
    forever begin
      #5 clk_tb = ~clk_tb;
    end
  end

  always @(clk_tb)
    $strobe("TB: Monitor: clk_tb changed to %b at time %0t", clk_tb, $time);

  integer i;
  initial begin
    $strobe("TB: Main stimulus initial block started at time %0t", $time);
    // Initialize signals
    write_en_tb = 0;
    wr_addr_tb = 0;
    wr_data_tb = 0;
    rd_addr_tb = 0;
    $strobe("TB: Stimulus signals initialized at time %0t", $time);
    
    // Wait for a few clock cycles to ensure clock is stable and running
    // before applying any synchronous stimulus.
    @(posedge clk_tb); // Wait for first edge
    $strobe("TB: Stimulus detected first posedge clk_tb at %0t", $time);
    @(posedge clk_tb); // Wait for second edge
    $strobe("TB: Stimulus detected second posedge clk_tb at %0t. Starting actual test logic.", $time);

    // Test 1: Basic write and read
    $display("\nTest 1: Basic write and read");
    
    // First write to all locations
    write_en_tb = 1;
    for (i = 0; i < DEPTH; i = i + 1) begin
      wr_addr_tb = i;
      wr_data_tb = i[1:0];
      #1; // give the DUT a little heads-up
      $display("TB: Writing addr=%0d, data=%b at time %0t", i, i[1:0], $time);
      @(posedge clk_tb);
      $strobe("TB: Write for addr=%0d completed at time %0t (next cycle start)", i, $time);
    end
    write_en_tb = 0;
    @(posedge clk_tb);  // Wait for last write to complete
    $strobe("TB: Last write signal de-asserted, current time %0t", $time);
    @(posedge clk_tb);  // Extra cycle to ensure write is complete in DUT
    $strobe("TB: Extra cycle for write completion done, current time %0t", $time);


    // Now read back all locations
    for (i = 0; i < DEPTH; i = i + 1) begin
      rd_addr_tb = i;
      #1; 
      $display("TB: Reading addr=%0d at time %0t", i, $time);
      @(posedge clk_tb);  // First cycle: latch the address
      $strobe("TB: Read addr %0d latched at time %0t", i, $time);
      @(posedge clk_tb);  // Second cycle: data is now available
      $strobe("TB: Data for addr %0d available at time %0t", i, $time);
      $display("TB: Read result for addr=%0d: got %b, expected %b at time %0t", i, rd_data_dut, i[1:0], $time);
      if (rd_data_dut !== i[1:0]) begin
        $fatal(1, "❌ ROM mismatch at addr %0d: got %b, expected %b", i, rd_data_dut, i[1:0]);
      end else begin
        $display("Addr %0d → %b (OK)", i, rd_data_dut);
      end
    end

    // Test 2: Invalid address testing
    $display("\nTest 2: Invalid address testing");
    // Test invalid write address
    write_en_tb = 1;
    wr_addr_tb = DEPTH;  // Invalid address
    wr_data_tb = 2'b11;
    $display("TB: Testing invalid write addr=%0d at time %0t", DEPTH, $time);
    @(posedge clk_tb);
    $strobe("TB: Invalid write attempt done at time %0t", $time);
    write_en_tb = 0;
    
    // Test invalid read address
    rd_addr_tb = DEPTH;  // Invalid address
    $display("TB: Testing invalid read addr=%0d at time %0t", DEPTH, $time);
    @(posedge clk_tb);
    $strobe("TB: Invalid read addr %0d latched at time %0t", DEPTH, $time);
    @(posedge clk_tb);  // Wait for registered output
    $strobe("TB: Data for invalid read addr %0d available at time %0t", DEPTH, $time);
    if (rd_data_dut !== 2'bxx) begin
      $fatal(1, "❌ Invalid read address test failed: got %b, expected xx", rd_data_dut);
    end else begin
      $display("Invalid address test passed (OK)");
    end

    // Test 3: Read/Write collision
    $display("\nTest 3: Read/Write collision");
    write_en_tb = 1;
    wr_addr_tb = 2;  // Write to address 2
    wr_data_tb = 2'b11;
    rd_addr_tb = 2;  // Read from same address
    $display("TB: Testing read/write collision at addr=2 at time %0t", $time);
    @(posedge clk_tb);
    $strobe("TB: R/W collision cycle 1 done at time %0t", $time);
    @(posedge clk_tb);  // Wait for registered output
    $strobe("TB: R/W collision data available at time %0t", $time);
    if (rd_data_dut !== 2'b11) begin
      $fatal(1, "❌ Read/Write collision test failed: got %b, expected 11", rd_data_dut);
    end else begin
      $display("Read/Write collision test passed (OK)");
    end

    $display("\n✅ PASS: All sequence_rom tests completed successfully for DEPTH=%0d", DEPTH);
    $finish;
  end
endmodule