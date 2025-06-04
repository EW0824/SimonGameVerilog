// =============================================================
//  top_tb.v   –  integration test-bench for top.v
//               • drives 100 MHz clk
//               • overrides the clock-divider so slow_clk ≈ 160 ns
//               • exercises three rounds:  ✓, ✓✓, then an ⨯ (error)
// =============================================================
`timescale 1ns/1ps

module top_tb;

  //------------------------------------------------------------------
  // 1. local parameters
  //------------------------------------------------------------------
  localparam FAST_CLK_PER_NS = 10;        // 100 MHz system clock
  localparam FAST_HALF       = FAST_CLK_PER_NS/2;
  localparam BTN_HOLD_NS     = 200;       // keep button high ≥ 1 slow-clk edge

  //------------------------------------------------------------------
  // 2. DUT I/O
  //------------------------------------------------------------------
  reg        clk   = 1'b0;
  reg        reset = 1'b1;
  reg  [3:0] btn   = 4'b0000;             // BTNU,L,R,D active-high

  wire [3:0] led;
  wire       error_led;
  wire [6:0] seg;
  wire [3:0] an;

  //------------------------------------------------------------------
  // 3. instantiate DUT
  //------------------------------------------------------------------
  top dut (
      .clk      (clk),
      .reset    (reset),
      .btn      (btn),
      .led      (led),
      .error_led(error_led),
      .seg      (seg),
      .an       (an)
  );

  // ---> ****  ACCELERATE the clock divider  **** <---
  //      Make slow_clk = clk_div.cnt[3] (toggles every 8 sys-clks ≈ 160 ns)
  defparam dut.clkdiv.BIT = 3;

  //------------------------------------------------------------------
  // 4. generate the 100 MHz system clock
  //------------------------------------------------------------------
  always #FAST_HALF clk = ~clk;

  //------------------------------------------------------------------
  // 5. handy task to press a button (val 0-3) once
  //------------------------------------------------------------------
  task press_button(input [1:0] bval);
    begin
      btn            = 4'b0001 << bval;   // one-hot
      #(BTN_HOLD_NS);                     // hold long enough for sync
      btn            = 4'b0000;
    end
  endtask

  //------------------------------------------------------------------
  // 6. short-hand access to DUT internals (for clean code)
  //------------------------------------------------------------------
  //  (works with any tool that allows hierarchical refs in TB)
  localparam S_INIT  = 3'd0,
             S_PLAY  = 3'd1,
             S_WAIT  = 3'd2,
             S_CHECK = 3'd3,
             S_ERROR = 3'd4;

  wire [2:0] state      = dut.fsm_state;
  wire [3:0] round_cnt  = dut.fsm.round_cnt;
  wire [3:0] input_idx  = dut.fsm.input_idx;

  //------------------------------------------------------------------
  // 7. the actual stimulus + checking
  //------------------------------------------------------------------
  initial begin
    $display("\n=== TOP-LEVEL Simon test (buttons) ===");

    //------------------------------------------------------------
    // 7.1  apply reset for 3 system cycles
    //------------------------------------------------------------
    repeat (3) @(posedge clk);
    reset = 1'b0;
    $display("T=%0t  reset released", $time);

    //------------------------------------------------------------
    // 7.2  wait for initial loading to finish (state -> S_PLAY)
    //------------------------------------------------------------
    wait (state == S_PLAY);
    #1; // settle
    if (round_cnt != 1) begin
      $display("FAIL: after init, round_cnt=%0d (expected 1)", round_cnt);
      $finish;
    end
    $display("T=%0t  entered Round-1 play", $time);

    //------------------------------------------------------------
    // 7.3  ********  ROUND-1 (single correct)  ********
    //------------------------------------------------------------
    wait (state == S_WAIT);    // awaiting user
    press_button(2'd0);        // BTNU – correct

    // wait until next S_PLAY
    wait (state == S_PLAY);
    #1;
    if (round_cnt != 2) begin
      $display("FAIL: did not advance to Round-2 (round_cnt=%0d)", round_cnt);
      $finish;
    end
    $display("T=%0t  Round-1 OK  -> Round-2", $time);

    //------------------------------------------------------------
    // 7.4  ********  ROUND-2 (two corrects)  ********
    //------------------------------------------------------------
    // (sequence is 0 then 1)
    wait (state == S_WAIT);
    press_button(2'd0);          // first OK
    wait (state == S_WAIT);
    press_button(2'd1);          // second OK

    wait (state == S_PLAY);
    #1;
    if (round_cnt != 3) begin
      $display("FAIL: did not advance to Round-3 (round_cnt=%0d)", round_cnt);
      $finish;
    end
    $display("T=%0t  Round-2 OK  -> Round-3", $time);

    //------------------------------------------------------------
    // 7.5  ********  ROUND-3 (inject WRONG)  ********
    //------------------------------------------------------------
    wait (state == S_WAIT);
    press_button(2'd3);          // WRONG on purpose

    wait (state == S_ERROR);
    #1;
    if (!error_led) begin
      $display("FAIL: state S_ERROR but error_led low");
      $finish;
    end
    $display("T=%0t  Error detected correctly", $time);

    //------------------------------------------------------------
    // 7.6  recovery – press any button to restart game
    //------------------------------------------------------------
    press_button(2'd0);
    wait (state == S_PLAY);
    #1;
    if (round_cnt != 1 || error_led) begin
      $display("FAIL: recovery failed (round_cnt=%0d error_led=%b)",
               round_cnt, error_led);
      $finish;
    end
    $display("T=%0t  Recovery OK, back to Round-1", $time);
    $display("\n=== TEST PASSED ===\n");
    $finish;
  end
endmodule