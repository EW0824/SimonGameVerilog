`timescale 1ns / 1ps

module simon_fsm_tb;

  // Parameters
  localparam N_TB = 10;
  localparam TICK_PERIOD = 1000; // ns, for a 1kHz "tick" for faster simulation.
                                 // Simulates 1ms per FSM "tick".
                                 // 1_000_000ps per FSM "tick"

  // DUT Inputs
  reg clk_tick;
  reg reset;
  reg start_play;
  wire [1:0] seq_val_tb; // MUST BE WIRE due to continuous assignment
  reg btn_valid;
  reg [1:0] btn_val;

  // DUT Outputs
  wire [3:0] led;
  wire       error_led;
  wire [3:0] rd_addr;

  // Test variables
  reg [1:0] incorrect_val; // For error testing

  // Instantiate DUT (ensure your FSM file is simon_fsm.v)
  simon_fsm #(.N(N_TB)) dut (
    .clk_tick(clk_tick),
    .reset(reset),
    .start_play(start_play),
    .seq_val(seq_val_tb),
    .btn_valid(btn_valid),
    .btn_val(btn_val),
    .led(led),
    .error_led(error_led),
    .rd_addr(rd_addr)
  );

  // ROM model
  reg [1:0] sequence_memory [0:15];
  assign seq_val_tb = sequence_memory[rd_addr];

  // Clock generation
  initial begin
    clk_tick = 0;
    forever #(TICK_PERIOD / 2) clk_tick = ~clk_tick; // Creates a 1kHz clock if TICK_PERIOD is 1000ns
  end

  // Helper task for button press
  task press_button;
    input [1:0] value;
    begin
      #(TICK_PERIOD / 4); // Wait some time before asserting valid (e.g., 250ns)
      btn_val = value;
      btn_valid = 1'b1;
      @ (posedge clk_tick); // Hold for one clock cycle (FSM latches on this edge)
      btn_valid = 1'b0;
      #(TICK_PERIOD / 4); // Debounce/settle time
    end
  endtask

  // Test sequence
  initial begin
    // Initialize ROM
    sequence_memory[0] = 2'd0; sequence_memory[1] = 2'd1;
    sequence_memory[2] = 2'd2; sequence_memory[3] = 2'd3;
    sequence_memory[4] = 2'd0;
    for (integer i = 5; i < 16; i = i + 1) sequence_memory[i] = 2'b00;

    // Initialize inputs
    reset = 1'b1;
    start_play = 1'b0;
    btn_valid = 1'b0;
    btn_val = 2'd0;

    $display("T=%0t: [%s] Starting Testbench...", $time, `__FILE__);

    // 1. Apply reset
    // Current time is 0.
    // Let reset be active for 2 full clock periods.
    // A full clock period is TICK_PERIOD (1000ns).
    // Posedge at 0, 500, 1000, 1500, 2000, 2500...
    #(TICK_PERIOD * 2); // Advances time by 2000ns. Current time becomes 2000ns.
                        // Reset is high during ticks at T=500, T=1500.
    reset = 1'b0;
    $display("T=%0t: Reset released. FSM should be in S_INIT (val %d).", $time, dut.S_INIT);

    // Wait for the next posedge for FSM to process deasserted reset.
    // If reset was released at T=2000ns, next posedge is T=2500ns.
    @ (posedge clk_tick);
    // At T=2500ns, FSM processes reset=0.

    // Checks after reset has been processed
    if (dut.state !== dut.S_INIT) $error("FAIL: FSM not in S_INIT after reset. State: %d", dut.state);
    if (led !== 4'b0000) $error("FAIL: LEDs not off in S_INIT. LED: %b", led);
    if (error_led !== 1'b0) $error("FAIL: Error LED not off in S_INIT. Error LED: %b", error_led);
    // Initial round_cnt in FSM is 0, becomes 1 upon starting.
    if (dut.round_cnt !== 4'd0) $error("FAIL: Round count not 0 in S_INIT. Is: %d", dut.round_cnt);


    // 2. Start the game
    // Current time is T=2500ns (after the posedge clk_tick that processed reset deassertion).
    // Next posedge clk_tick will be at T=3500ns.
    // We need start_play to be high *before* T=3500ns.
    #( (TICK_PERIOD / 2) - 10 ); // Advance close to, but before, the next posedge.
                                 // If TICK_PERIOD=1000, advances by 500-10 = 490ns.
                                 // Time becomes 2500 + 490 = 2990ns.
    start_play = 1'b1;
    $display("T=%0t: Asserted start_play (stable before edge).", $time); // Time is 2990ns.

    @ (posedge clk_tick); // This is the clock edge at T=3500ns.
                          // FSM samples start_play, which has been stable as 1.
    start_play = 1'b0;    // De-assert after the edge. (FSM should have latched it)

    // Checks after start_play assertion and clock tick
    // At T=3500ns, FSM should have transitioned S_INIT -> S_PLAY
    if (dut.state !== dut.S_PLAY) $error("FAIL: FSM not in S_PLAY after start_play. State: %d", dut.state);
    if (dut.round_cnt !== 4'd1) $error("FAIL: Round count not 1 after start_play. Is: %d", dut.round_cnt);
    $display("T=%0t: Game started. Round %d. State S_PLAY (val %d).", $time, dut.round_cnt, dut.S_PLAY);

    // --- Round 1 ---
    // At T=3500ns, FSM is in S_PLAY, round_cnt=1, play_idx=0.
    // rd_addr should be 0 (set on transition to S_PLAY).
    // led should be sequence_memory[0].
    // play_idx becomes 1.
    $display("T=%0t: --- Round 1 Play ---", $time);
    if (rd_addr !== 4'd0) $error("FAIL R1P: rd_addr not 0 for item 0. Is %d", rd_addr);
    if (led !== (4'b0001 << sequence_memory[0])) $error("FAIL R1P: LED for item 0 incorrect. Expected %b, Got %b", (4'b0001 << sequence_memory[0]), led);
    $display("T=%0t: R1 Play: Displayed item 0 (val %d), LED: %b. dut.play_idx is now %d", $time, sequence_memory[0], led, dut.play_idx);

    // Next clock edge: T=4500ns.
    // S_PLAY: play_idx (1) == round_cnt (1) is FALSE for play_idx < round_cnt.
    // Actually, play_idx was incremented to 1. Now play_idx (1) < round_cnt (1) is FALSE.
    // So, S_PLAY finishes. Transitions to S_WAIT. input_idx=0, rd_addr=0.
    @ (posedge clk_tick);
    if (dut.state !== dut.S_WAIT) $error("FAIL R1P: Not in S_WAIT. State: %d", dut.state);
    if (dut.input_idx !== 4'd0) $error("FAIL R1P: input_idx not 0 in S_WAIT. Is: %d", dut.input_idx);
    if (rd_addr !== 4'd0) $error("FAIL R1P: rd_addr not 0 for S_WAIT (for seq[0]). Is %d", rd_addr);
    $display("T=%0t: R1 Play done. Entered S_WAIT. Expecting input for item 0.", $time);

    // User provides correct input for item 0
    // Current time T=4500ns. press_button advances time.
    press_button(sequence_memory[0]); // Presses button sequence_memory[0]
                                      // press_button: #(250ns) -> T=4750ns. btn_valid=1.
                                      //               @(posedge clk_tick) -> T=5500ns. FSM latches btn.
                                      //               btn_valid=0. #(250ns) -> T=5750ns.
    $display("T=%0t: R1 User: Provided correct input %d.", $time, sequence_memory[0]); // Time is 5750ns.

    // At T=5500ns (within press_button), FSM was in S_WAIT, saw btn_valid.
    // It latched btn_val and transitioned to S_CHECK.
    // So, after press_button returns (T=5750ns), dut.state should be S_CHECK.
    if (dut.state !== dut.S_CHECK) $error("FAIL R1C: Not in S_CHECK. State: %d", dut.state);
    if (dut.latched_btn !== sequence_memory[0]) $error("FAIL R1C: Button not latched correctly.");

    // Next clock edge: T=6500ns.
    // S_CHECK processes: latched_btn (seq[0]) == seq_val (seq[0]). Correct.
    // input_idx (0) == round_cnt (1) - 1. Correct, round complete.
    // Transitions to S_PLAY. round_cnt=2, play_idx=0.
    @ (posedge clk_tick);
    if (dut.state !== dut.S_PLAY) $error("FAIL R1C: Not in S_PLAY for R2. State: %d", dut.state);
    if (error_led !== 1'b0) $error("FAIL R1C: Error LED on after correct input.");
    if (dut.round_cnt !== 4'd2) $error("FAIL R1C: Round count not 2. Is %d", dut.round_cnt);
    $display("T=%0t: R1 Correct. Round 1 Complete. To S_PLAY for Round 2.", $time); // Time is 6500ns.

    // --- Round 2 --- (round_cnt = 2. Play seq[0], then seq[1])
    // At T=6500ns, FSM is in S_PLAY, round_cnt=2, play_idx=0.
    // rd_addr=0. led=seq[0]. play_idx becomes 1.
    $display("T=%0t: --- Round 2 Play ---", $time);
    if (rd_addr !== 4'd0) $error("FAIL R2P0: rd_addr not 0 for item 0. Is %d", rd_addr);
    if (led !== (4'b0001 << sequence_memory[0])) $error("FAIL R2P0: LED for item 0 incorrect. Got %b", led);
    $display("T=%0t: R2 Play: Displayed item 0 (val %d), LED: %b. dut.play_idx is now %d", $time, sequence_memory[0], led, dut.play_idx);

    // Next clock edge: T=7500ns.
    // S_PLAY: play_idx (1) < round_cnt (2). True.
    // rd_addr=1. led=seq[1]. play_idx becomes 2.
    @ (posedge clk_tick);
    if (dut.state !== dut.S_PLAY) $error("FAIL R2P1: Still expected S_PLAY. State: %d", dut.state);
    if (rd_addr !== 4'd1) $error("FAIL R2P1: rd_addr not 1 for item 1. Is %d", rd_addr);
    if (led !== (4'b0001 << sequence_memory[1])) $error("FAIL R2P1: LED for item 1 incorrect. Got %b", led);
    $display("T=%0t: R2 Play: Displayed item 1 (val %d), LED: %b. dut.play_idx is now %d", $time, sequence_memory[1], led, dut.play_idx);

    // Next clock edge: T=8500ns.
    // S_PLAY: play_idx (2) < round_cnt (2). False.
    // Transitions to S_WAIT. input_idx=0, rd_addr=0.
    @ (posedge clk_tick);
    if (dut.state !== dut.S_WAIT) $error("FAIL R2P: Not in S_WAIT. State: %d", dut.state);
    if (dut.input_idx !== 4'd0) $error("FAIL R2P: input_idx not 0 in S_WAIT. Is: %d", dut.input_idx);
    if (rd_addr !== 4'd0) $error("FAIL R2P: rd_addr not 0 for S_WAIT (for seq[0]). Is %d", rd_addr);
    $display("T=%0t: R2 Play done. Entered S_WAIT. Expecting input for item 0 of R2.", $time);

    // User provides correct input for item 0 (seq[0])
    // Current time T=8500ns.
    press_button(sequence_memory[0]); // Advances to T=8500+250+1000+250 = 10000ns
    $display("T=%0t: R2 User: Correct input %d for item 0.", $time, sequence_memory[0]); // Time is 10000ns
    // At T=8500+250+1000 = 9750ns (within press_button), FSM transitioned S_WAIT -> S_CHECK.
    if (dut.state !== dut.S_CHECK) $error("FAIL R2C0: Not in S_CHECK. State: %d", dut.state);

    // Next clock edge: T=10500ns.
    // S_CHECK processes item 0: latched_btn (seq[0]) == seq_val (seq[0]). Correct.
    // input_idx (0) == round_cnt (2) - 1. False. (0 != 1)
    // More inputs needed. input_idx becomes 1. rd_addr becomes 1. Transitions to S_WAIT.
    @ (posedge clk_tick);
    if (dut.state !== dut.S_WAIT) $error("FAIL R2C0: Not in S_WAIT for item 1. State: %d", dut.state);
    if (dut.input_idx !== 4'd1) $error("FAIL R2C0: input_idx not 1. Is %d", dut.input_idx);
    if (rd_addr !== 4'd1) $error("FAIL R2C0: rd_addr not 1 for next input (seq[1]). Is %d", rd_addr);
    $display("T=%0t: R2 User: Correct for item 0. Entered S_WAIT for item 1.", $time); // Time is 10500ns

    // User provides correct input for item 1 (seq[1])
    // Current time T=10500ns.
    press_button(sequence_memory[1]); // Advances to T=10500+250+1000+250 = 12000ns
    $display("T=%0t: R2 User: Correct input %d for item 1.", $time, sequence_memory[1]); // Time is 12000ns
    // At T=10500+250+1000 = 11750ns (within press_button), FSM transitioned S_WAIT -> S_CHECK.
    if (dut.state !== dut.S_CHECK) $error("FAIL R2C1: Not in S_CHECK. State: %d", dut.state);

    // Next clock edge: T=12500ns.
    // S_CHECK processes item 1: latched_btn (seq[1]) == seq_val (seq[1]). Correct.
    // input_idx (1) == round_cnt (2) - 1. True. (1 == 1). Round complete.
    // Transitions to S_PLAY. round_cnt=3, play_idx=0.
    @ (posedge clk_tick);
    if (dut.state !== dut.S_PLAY) $error("FAIL R2C1: Not in S_PLAY for R3. State: %d", dut.state);
    if (error_led !== 1'b0) $error("FAIL R2C1: Error LED on.");
    if (dut.round_cnt !== 4'd3) $error("FAIL R2C1: Round count not 3. Is %d", dut.round_cnt);
    $display("T=%0t: R2 Correct. Round 2 Complete. To S_PLAY for Round 3.", $time); // Time is 12500ns

    // --- Round 3 (Error Test) ---
    // At T=12500ns, FSM is S_PLAY, round_cnt=3, play_idx=0.
    $display("T=%0t: --- Round 3 Play (then error test) ---", $time);
    // S_PLAY item 0 (seq[0]): T=12500ns. rd_addr=0, led=seq[0], play_idx=1.
    // @ (posedge clk_tick) -> T=13500ns.
    // S_PLAY item 1 (seq[1]): T=13500ns. rd_addr=1, led=seq[1], play_idx=2.
    // @ (posedge clk_tick) -> T=14500ns.
    // S_PLAY item 2 (seq[2]): T=14500ns. rd_addr=2, led=seq[2], play_idx=3.
    // @ (posedge clk_tick) -> T=15500ns.
    // S_PLAY: play_idx (3) < round_cnt (3). False.
    // Transitions to S_WAIT. input_idx=0, rd_addr=0.
    @ (posedge clk_tick); // Consumes T=13500ns (for seq[0] display to finish, play_idx becomes 1)
    @ (posedge clk_tick); // Consumes T=14500ns (for seq[1] display to finish, play_idx becomes 2)
    @ (posedge clk_tick); // Consumes T=15500ns (for seq[2] display to finish, play_idx becomes 3, then transition to S_WAIT)

    if (dut.state !== dut.S_WAIT) $error("FAIL R3P: Not in S_WAIT. State is %d", dut.state);
    if (dut.input_idx !== 4'd0) $error("FAIL R3P: input_idx not 0 in S_WAIT. Is %d", dut.input_idx);
    $display("T=%0t: R3 Play done. Entered S_WAIT. Expecting input for item 0 (will provide error).", $time); // Time is 15500ns

    // User provides incorrect input for item 0 of round 3
    // Current time T=15500ns.
    incorrect_val = ~sequence_memory[0]; // An incorrect value (e.g., if seq[0]=00, incorrect=11)
    press_button(incorrect_val); // Advances to T=15500+250+1000+250 = 17000ns
    $display("T=%0t: R3 User: Incorrect input %d (expected %d).", $time, incorrect_val, sequence_memory[0]); // Time is 17000ns
    // At T=15500+250+1000 = 16750ns (within press_button), FSM transitioned S_WAIT -> S_CHECK.
    if (dut.state !== dut.S_CHECK) $error("FAIL R3E: Not in S_CHECK. State: %d", dut.state);

    // Next clock edge: T=17500ns.
    // S_CHECK processes: latched_btn (incorrect) != seq_val (seq[0]). Incorrect.
    // Transitions to S_ERROR. error_led=1.
    @ (posedge clk_tick);
    if (dut.state !== dut.S_ERROR) $error("FAIL R3E: Not in S_ERROR. State: %d", dut.state);
    if (error_led !== 1'b1) $error("FAIL R3E: Error LED not on.");
    $display("T=%0t: R3 Incorrect. Entered S_ERROR.", $time); // Time is 17500ns

    // Recover from error
    // Current time T=17500ns.
    #(TICK_PERIOD * 2); // Stay in error for a bit. Advances by 2000ns. Time becomes 19500ns.
    $display("T=%0t: R3 Error Recovery: Pressing button.", $time); // Time is 19500ns.

    press_button(2'd0); // Any button press. Advances by 1500ns. Time becomes 21000ns.
                        // At T=19500+250+1000 = 20750ns (within press_button), FSM S_ERROR -> S_PLAY.

    // FSM should go S_ERROR -> S_PLAY (restarting at round 1)
    // After press_button returns (T=21000ns), state should be S_PLAY.
    if (dut.state !== dut.S_PLAY) $error("FAIL R3R: Not in S_PLAY after error recovery. State: %d", dut.state);
    if (error_led !== 1'b0) $error("FAIL R3R: Error LED not off.");
    if (dut.round_cnt !== 4'd1) $error("FAIL R3R: Round count not reset to 1. Is %d", dut.round_cnt);
    $display("T=%0t: R3 Recovered. Restarting at Round 1.", $time); // Time is 21000ns.

    #(TICK_PERIOD * 5); // Let it run a bit more.
    $display("T=%0t: Testbench finished.", $time);
    $finish;
  end

  // Optional: Monitor signals for easier debugging
  // always @(posedge clk_tick) begin
  //   $strobe("T=%0t: state=%d, play_idx=%d, input_idx=%d, round_cnt=%d | rd_addr=%d, seq_val_tb=%d | led=%b, error_led=%b | btn_v=%b, btn_val=%d",
  //          $time, dut.state, dut.play_idx, dut.input_idx, dut.round_cnt, rd_addr, seq_val_tb, led, error_led, btn_valid, btn_val);
  // end

endmodule
