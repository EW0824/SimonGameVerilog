// tb_clock_divider.v
`timescale 1ns/1ps

module tb_clock_divider;

    // Parameters for the DUT (can be overridden if needed for faster sim)
    // Default WIDTH=27, BIT=26 from DUT is too slow for quick TB.
    // Let's use smaller values for the testbench.
    localparam TB_WIDTH = 8; // Generates slow_clk from cnt[TB_BIT]
    localparam TB_BIT   = 7; // slow_clk will toggle every 2^(TB_BIT) cycles = 128 cycles

    // Inputs
    reg clk_tb;
    reg reset_tb;

    // Outputs
    wire slow_clk_dut;

    // Instantiate the DUT
    clock_divider #(
        .WIDTH(TB_WIDTH),
        .BIT(TB_BIT)
    ) dut (
        .clk      (clk_tb),
        .reset    (reset_tb),
        .slow_clk (slow_clk_dut)
    );

    // Clock generation (e.g., 100 MHz -> 10ns period)
    initial begin
        clk_tb = 0;
        forever #5 clk_tb = ~clk_tb; // 10ns period
    end

    // Main test sequence
    initial begin
        $display("Starting clock_divider testbench (WIDTH=%0d, BIT=%0d)...", TB_WIDTH, TB_BIT);

        // 1. Initial Reset
        reset_tb = 1'b1;
        $display("[%0t] Applying reset...", $time);
        repeat (5) @(posedge clk_tb); // Hold reset for a few cycles
        
        reset_tb = 1'b0;
        $display("[%0t] Releasing reset.", $time);

        // 2. Monitor slow_clk toggle
        // With TB_WIDTH=8, TB_BIT=7, slow_clk is cnt[7].
        // cnt[7] will go high after 2^7 = 128 cycles of clk_tb.
        // It will go low after another 128 cycles.
        // One full period of slow_clk = 2 * 2^TB_BIT = 2 * 128 = 256 input clock cycles.

        $display("[%0t] Waiting for first rising edge of slow_clk_dut...", $time);
        @(posedge slow_clk_dut);
        $display("✅ [%0t] PASS: First rising edge of slow_clk_dut detected.", $time);

        $display("[%0t] Waiting for first falling edge of slow_clk_dut...", $time);
        @(negedge slow_clk_dut);
        $display("✅ [%0t] PASS: First falling edge of slow_clk_dut detected.", $time);

        // 3. Test dynamic reset (optional, but good)
        $display("[%0t] Waiting for second rising edge of slow_clk_dut before dynamic reset...", $time);
        @(posedge slow_clk_dut);
        $display("✅ [%0t] Second rising edge of slow_clk_dut detected.", $time);
        
        $display("[%0t] Applying dynamic reset...", $time);
        reset_tb = 1'b1;
        @(posedge clk_tb);
        #1; // Let signals settle
        if (slow_clk_dut !== 1'b0) begin
            $display("❌ FAIL: slow_clk_dut did not go to 0 after dynamic reset. Value: %b", slow_clk_dut);
            $finish;
        end else begin
            $display("✅ [%0t] PASS: slow_clk_dut is 0 after dynamic reset asserted.", $time);
        end

        reset_tb = 1'b0;
        $display("[%0t] Releasing dynamic reset.", $time);

        // Wait for slow_clk to start again
        $display("[%0t] Waiting for slow_clk_dut to go high again after dynamic reset...", $time);
        @(posedge slow_clk_dut);
        $display("✅ [%0t] PASS: slow_clk_dut went high again after dynamic reset released.", $time);


        $display("\nAll clock_divider tests completed successfully!");
        $finish;
    end

    // Waveform dump
    initial begin
        $dumpfile("tb_clock_divider.vcd");
        $dumpvars(0, tb_clock_divider);
    end

endmodule 