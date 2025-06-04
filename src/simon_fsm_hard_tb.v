// simon_fsm_hard_tb.v
`timescale 1ns/1ps
module simon_fsm_hard_tb;

  //---------------------------------------------------------------------------
  // 1.  Clock generation (100 MHz → 10 ns period)
  //---------------------------------------------------------------------------
  reg clk = 0;
  always #5 clk = ~clk;          // toggle every 5 ns

  //---------------------------------------------------------------------------
  // 2.  DUT I/O
  //---------------------------------------------------------------------------
  reg        reset;
  reg        btn_valid;
  reg [1:0]  btn_val;

  wire [3:0] led;
  wire       error_led;
  wire [2:0] state;
  wire [3:0] init_cnt;

  //---------------------------------------------------------------------------
  // 3.  Instantiate DUT with a short LED hold (LED_HOLD = 2 → fast sim)
  //---------------------------------------------------------------------------
  simon_fsm_hard #(.LED_HOLD(2)) dut (
      .clk_tick (clk),
      .reset    (reset),
      .btn_valid(btn_valid),
      .btn_val  (btn_val),
      .led      (led),
      .error_led(error_led),
      .state    (state),
      .init_cnt (init_cnt)
  );

  //---------------------------------------------------------------------------
  // 4.  Convenience tasks
  //---------------------------------------------------------------------------
  // 4‑a: pulse one button (btn_valid HIGH for 1 clk)
  task automatic pulse_button(input [1:0] b);
    begin
      @(posedge clk);
      btn_val   <= b;
      btn_valid <= 1;
      @(posedge clk);
      btn_valid <= 0;
    end
  endtask

  // 4‑b: wait until DUT is in "waiting‑for‑input" state (S_WAIT = 3'd2)
  task automatic wait_for_input;
    begin
      while (state != 3'd2) @(posedge clk);
    end
  endtask

  //---------------------------------------------------------------------------
  // 5.  Test suites
  //---------------------------------------------------------------------------
  task automatic run_correct_game;
    integer round, i;
    begin
      $display("\n=== TEST 1: Perfect play ===");
      for (round = 0; round < 4; round = round + 1) begin
        wait_for_input();
        for (i = 0; i <= round; i = i + 1) begin
          pulse_button(i[1:0]);      // press 0, then 0 1, then 0 1 2, …
          @(posedge clk);
        end
      end
      repeat (10) @(posedge clk);    // let FSM settle
      if (state == 3'd0 && !error_led)
        $display("PASS  Perfect play accepted.");
      else
        $display("FAIL  Perfect play **not** accepted!");
    end
  endtask

  task automatic wrong_first_press;
    begin
      $display("\n=== TEST 2: Wrong on very first press ===");
      wait_for_input();
      pulse_button(2'd1);            // wrong (should be 0)
      @(posedge clk);
      if (state == 3'd4 && error_led)
        $display("PASS  Immediate error detected.");
      else
        $display("FAIL  Immediate error NOT detected!");
    end
  endtask

  task automatic wrong_second_round;
    begin
      $display("\n=== TEST 3: Wrong during second round ===");
      // ‑‑ round 1 correct
      wait_for_input();  pulse_button(2'd0); @(posedge clk);
      // ‑‑ round 2: first press correct …
      wait_for_input();  pulse_button(2'd0); @(posedge clk);
      //                … second press wrong
      wait_for_input();  pulse_button(2'd2); @(posedge clk);
      if (state == 3'd4 && error_led)
        $display("PASS  Error detected in round 2.");
      else
        $display("FAIL  Error NOT detected in round 2!");
    end
  endtask

  //---------------------------------------------------------------------------
  // 6.  Stimulus & scoreboard
  //---------------------------------------------------------------------------
  initial begin
    // dump VCD for waveform viewers
    $dumpfile("simon_fsm_hard_tb.vcd");
    $dumpvars(0, simon_fsm_hard_tb);

    // global reset
    reset = 1;  btn_valid = 0;  btn_val = 0;
    repeat (5) @(posedge clk);
    reset = 0;

    //---------------- perfect play ----------------
    run_correct_game();

    //---------------- wrong first press ----------- 
    reset = 1; repeat (2) @(posedge clk); reset = 0;
    wrong_first_press();

    //---------------- wrong in second round ------- 
    reset = 1; repeat (2) @(posedge clk); reset = 0;
    wrong_second_round();

    //-----------------------------------------------------------------------
    // 7.  OPTIONAL: brute‑force enumeration (commented out – long run)
    //-----------------------------------------------------------------------
    integer a, b, c, d;
    $display("\n=== TEST 4: Brute‑force all 4‑button combos ===");
    for (a=0; a<4; a=a+1)
      for (b=0; b<4; b=b+1)
        for (c=0; c<4; c=c+1)
          for (d=0; d<4; d=d+1) begin
            // reset before each 4‑button attempt
            reset = 1; repeat (2) @(posedge clk); reset = 0;
            // wait for round 1
            wait_for_input(); pulse_button(a);
            // round 2
            wait_for_input(); pulse_button(a);
            wait_for_input(); pulse_button(b);
            // round 3
            wait_for_input(); pulse_button(a);
            wait_for_input(); pulse_button(b);
            wait_for_input(); pulse_button(c);
            // round 4
            wait_for_input(); pulse_button(a);
            wait_for_input(); pulse_button(b);
            wait_for_input(); pulse_button(c);
            wait_for_input(); pulse_button(d);
            // let FSM settle, then record pass/fail
            repeat (10) @(posedge clk);
            if (error_led !== (d!=3 || c!=2 || b!=1 || a!=0))
              $display("Mismatch for seq %0d%0d%0d%0d",a,b,c,d);
          end
    $display("Brute‑force test finished.");

    $display("\nAll scripted tests finished.");
    #100 $finish;
  end

endmodule
