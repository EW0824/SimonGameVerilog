// ===========================================================
//  tb/tb_simon_fsm_hard.v   –  unit test for simon_fsm_hard.sv
// ===========================================================
`timescale 1ns/1ps

module simon_fsm_hard_tb;
    // ------------------------------------------------------------------
    // DUT parameters & local constants
    // ------------------------------------------------------------------
    localparam N            = 4;           // hard-coded seq length in DUT
    localparam TICK_PERIOD  = 1_000;       // 1 µs → 1 kHz test clock
    localparam S_INIT  = 3'd0,
               S_PLAY  = 3'd1,
               S_WAIT  = 3'd2,
               S_CHECK = 3'd3,
               S_ERROR = 3'd4;

    // ------------------------------------------------------------------
    // DUT I/O
    // ------------------------------------------------------------------
    reg        clk_tick  = 1'b0;
    reg        reset     = 1'b1;
    reg        btn_valid = 1'b0;
    reg  [1:0] btn_val   = 2'd0;

    wire [3:0] led;
    wire       error_led;
    wire [2:0] state;
    wire [3:0] init_cnt;

    // Instantiate the DUT
    simon_fsm_hard #(.N(N)) dut (
        .clk_tick  (clk_tick),
        .reset     (reset),
        .btn_valid (btn_valid),
        .btn_val   (btn_val),
        .led       (led),
        .error_led (error_led),
        .state     (state),
        .init_cnt  (init_cnt)
    );

    // ------------------------------------------------------------------
    // Test clock   (1 kHz for fast simulation)
    // ------------------------------------------------------------------
    always #(TICK_PERIOD/2) clk_tick = ~clk_tick;

    // ------------------------------------------------------------------
    // Helpful task – drive a one-tick button press
    // ------------------------------------------------------------------
    task press_button(input [1:0] val);
        begin
            btn_val   = val;
            btn_valid = 1'b1;
            @(posedge clk_tick);   // hold for 1 DUT tick
            @(posedge clk_tick);   // hold for another tick to ensure FSM sees it
            btn_valid = 1'b0;
        end
    endtask

    // ------------------------------------------------------------------
    // Stimulus + checking
    // ------------------------------------------------------------------
    initial begin
        $display("\n=== Simon FSM hard-coded test ===");

        //---------------------------------------------------------------
        // 1. apply reset for two ticks
        //---------------------------------------------------------------
        @(posedge clk_tick);   // 0.5 µs
        @(posedge clk_tick);   // 1.5 µs
        reset = 1'b0;
        $display("T=%0t ns  : reset released", $time);

        //---------------------------------------------------------------
        // 2. FSM initialises – wait until it leaves S_INIT
        //---------------------------------------------------------------
        wait (state == S_PLAY);   // after four ticks of init counter
        @(posedge clk_tick); // give FSM time to update state
        $display("T=%0t ns  : entered S_PLAY  (round_cnt=%0d)", $time, dut.round_cnt);

        //----------------------------------------------------------------
        // **************  ROUND-1  – one correct button ******************
        //----------------------------------------------------------------
        // Wait for S_WAIT, then push button 0
        wait (state == S_WAIT);
        @(posedge clk_tick); // ensure we're stable in S_WAIT
        @(posedge clk_tick); // wait one more tick to be sure
        if (state !== S_WAIT) begin
            $display("FAIL: Not in S_WAIT state (state=%0d)", state);
            $finish;
        end
        $display("T=%0t ns  : in S_WAIT, pressing button 0", $time);
        press_button(2'd0);

        // Verify S_CHECK state
        @(posedge clk_tick);
        if (state !== S_CHECK) begin
            $display("FAIL: Did not enter S_CHECK after button press (state=%0d, btn_valid=%b, btn_val=%b)", 
                    state, btn_valid, btn_val);
            $finish;
        end

        // Verify S_PLAY transition
        @(posedge clk_tick);
        if (state !== S_PLAY  || dut.round_cnt !== 2) begin
            $display("FAIL: Round-1  did not advance to Round-2 correctly (state=%0d, round_cnt=%0d)",
                      state, dut.round_cnt);
            $finish;
        end
        $display("T=%0t ns  : Round-1 cleared", $time);

        //----------------------------------------------------------------
        // **************  ROUND-2  – two correct buttons *****************
        //----------------------------------------------------------------
        wait (state == S_WAIT);
        @(posedge clk_tick); // ensure we're stable in S_WAIT
        @(posedge clk_tick); // wait one more tick to be sure
        if (state !== S_WAIT) begin
            $display("FAIL: Not in S_WAIT state (state=%0d)", state);
            $finish;
        end
        $display("T=%0t ns  : in S_WAIT, pressing first button for Round-2", $time);
        press_button(2'd0);               // correct 1st entry

        // Verify S_CHECK state
        @(posedge clk_tick);
        if (state !== S_CHECK) begin
            $display("FAIL: Did not enter S_CHECK after first button press (state=%0d)", state);
            $finish;
        end

        // Verify return to S_WAIT
        @(posedge clk_tick);
        if (state !== S_WAIT || dut.input_idx !== 1) begin
            $display("FAIL: Round-2  failed after first input (state=%0d, input_idx=%0d)",
                      state, dut.input_idx);
            $finish;
        end

        $display("T=%0t ns  : in S_WAIT, pressing second button for Round-2", $time);
        press_button(2'd1);               // correct 2nd entry

        // Verify S_CHECK state
        @(posedge clk_tick);
        if (state !== S_CHECK) begin
            $display("FAIL: Did not enter S_CHECK after second button press (state=%0d)", state);
            $finish;
        end

        // Verify S_PLAY transition
        @(posedge clk_tick);
        if (state !== S_PLAY  || dut.round_cnt !== 3) begin
            $display("FAIL: Round-2  did not advance to Round-3 (state=%0d, round_cnt=%0d)",
                      state, dut.round_cnt);
            $finish;
        end
        $display("T=%0t ns  : Round-2 cleared", $time);

        //----------------------------------------------------------------
        // **************  ROUND-3  – inject error ************************
        //----------------------------------------------------------------
        wait (state == S_WAIT);
        @(posedge clk_tick); // ensure we're stable in S_WAIT
        @(posedge clk_tick); // wait one more tick to be sure
        if (state !== S_WAIT) begin
            $display("FAIL: Not in S_WAIT state (state=%0d)", state);
            $finish;
        end
        $display("T=%0t ns  : in S_WAIT, pressing wrong button", $time);
        press_button(2'd3);               // WRONG on purpose

        // Verify S_CHECK state
        @(posedge clk_tick);
        if (state !== S_CHECK) begin
            $display("FAIL: Round-3  missing S_CHECK (state=%0d)", state);
            $finish;
        end

        // Verify S_ERROR transition
        @(posedge clk_tick);
        if (state !== S_ERROR || !error_led) begin
            $display("FAIL: Round-3  did not enter S_ERROR (state=%0d, error_led=%b)",
                      state, error_led);
            $finish;
        end
        $display("T=%0t ns  : Error detected correctly", $time);

        //----------------------------------------------------------------
        // **************  ERROR RECOVERY  ********************************
        //----------------------------------------------------------------
        press_button(2'd0);               // any button clears error
        @(posedge clk_tick);  // 1st tick: FSM samples btn_valid, schedules state <= S_CHECK
        @(posedge clk_tick);  // 2nd tick: FSM is now actually in S_CHECK!        
        if (state !== S_PLAY || dut.round_cnt !== 1 || error_led) begin
            $display("FAIL: Recovery failed – not back to Round-1 (state=%0d, round_cnt=%0d, error_led=%b)",
                      state, dut.round_cnt, error_led);
            $finish;
        end
        $display("T=%0t ns  : Recovery OK, back to Round-1", $time);

        //----------------------------------------------------------------
        // Finish
        //----------------------------------------------------------------
        $display("=== TEST PASSED ===\n");
        $finish;
    end
endmodule