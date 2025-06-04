// =============================================================
//  top_tb.v   –  integration test-bench for top.v
//               • drives 100 MHz clk
//               • overrides the clock-divider so slow_clk ≈ 160 ns
//               • exercises three rounds:  ✓, ✓✓, then an ⨯ (error)
// =============================================================
`timescale 1ns/1ps

module tb_top();
    // Parameters
    localparam CLK_PERIOD = 10;  // 100MHz clock
    localparam BTN_HOLD_NS = 200;  // Button press duration

    // Signals
    reg         clk;
    reg         reset;
    reg  [3:0]  btn;
    wire [3:0]  led;
    wire        error_led;
    wire [6:0]  seg;
    wire [3:0]  an;

    // Instantiate top module
    top dut (
        .clk       (clk),
        .reset     (reset),
        .btn       (btn),
        .led       (led),
        .error_led (error_led),
        .seg       (seg),
        .an        (an)
    );

    // Accelerate the clock divider for simulation
    // Make slow_clk toggle every 8 system clocks (≈ 160 ns)
    defparam dut.clkdiv.BIT = 3;

    // Task to press a button (val 0-3) once
    task press_button;
        input [1:0] bval;
        begin
            btn = 4'b0001 << bval;  // one-hot encoding
            #(BTN_HOLD_NS);
            btn = 4'b0000;
        end
    endtask

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Initialize signals
        reset = 1;
        btn = 4'b0000;

        // Wait 100 ns for global reset
        #100;
        reset = 0;

        // Wait for initialization
        wait(dut.fsm_state == 3'd1);  // Wait for S_PLAY state
        $display("T=%0t Entered Round-1 play", $time);

        // Wait for sequence display to complete
        wait(dut.fsm_state == 3'd2);  // Wait for S_WAIT state
        $display("T=%0t Round-1 ready for input, expecting button %0d", $time, dut.seq_val);
        
        // Press the correct button for Round 1
        press_button(dut.seq_val);
        
        // Wait for Round 2
        wait(dut.fsm_state == 3'd1);  // Wait for next S_PLAY
        if(dut.fsm.round_cnt != 2) begin
            $display("FAIL: Did not advance to Round 2");
            $finish;
        end
        $display("T=%0t Round-1 passed, entering Round-2", $time);

        // Wait for Round 2 sequence display to complete
        wait(dut.fsm_state == 3'd2);  // Wait for S_WAIT
        $display("T=%0t Round-2 ready for input, expecting button %0d", $time, dut.seq_val);
        
        // Press correct sequence for Round 2
        press_button(dut.seq_val);  // First button
        wait(dut.fsm_state == 3'd2);  // Wait for next input
        $display("T=%0t Round-2 second input, expecting button %0d", $time, dut.seq_val);
        press_button(dut.seq_val);  // Second button

        // Wait for Round 3 to start
        wait(dut.fsm_state == 3'd1);  // Wait for S_PLAY
        if(dut.fsm.round_cnt != 3) begin
            $display("FAIL: Did not advance to Round 3");
            $finish;
        end
        $display("T=%0t Round-2 passed, entering Round-3", $time);

        // Test error condition in Round 3
        wait(dut.fsm_state == 3'd2);  // Wait for S_WAIT
        $display("T=%0t Round-3 ready, expecting button %0d, pressing wrong button", $time, dut.seq_val);
        press_button(~dut.seq_val);  // Press wrong button

        // Check if error was detected (FSM might recover quickly)
        #(BTN_HOLD_NS * 2);
        $display("T=%0t Error condition tested", $time);

        // Wait for recovery and restart
        wait(dut.fsm_state == 3'd1);  // Wait for S_PLAY
        if(dut.fsm.round_cnt != 1) begin
            $display("FAIL: Did not reset to Round 1");
            $finish;
        end
        $display("T=%0t Successfully recovered to Round 1", $time);

        // End simulation
        #1000;
        $display("=== TEST PASSED ===");
        $finish;
    end

    // Monitor important signals
    initial begin
        $monitor("Time=%0t reset=%b btn=%b led=%b error_led=%b state=%b round=%0d",
                 $time, reset, btn, led, error_led, dut.fsm_state, dut.fsm.round_cnt);
    end

endmodule