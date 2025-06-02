`timescale 1ns / 1ps
// simon_fsm.v
// ——————————————————————————————————————————————————
// Now only handles PLAY → WAIT → CHECK → ERROR.
// Key changes from your original fsm:
//  • removed sequence-gen outputs: write_en, wr_addr, wr_data, lfsr_enable
//  • removed init_idx state & counting
//  • added `start_play` input: FSM sits in S_INIT until loader.done
//  • S_INIT now just waits for start_play, then kick off round_cnt=1
//
// Ports:
//  - clk_tick, reset, start_play
//  - seq_val (from sequence_rom), btn_valid, btn_val
//  - led[3:0], error_led
module simon_fsm #(
  parameter N = 10
)(
  input  wire        clk_tick,     // ~1Hz tick
  input  wire        reset,
  input  wire        start_play,   // high when sequence_loader.done

  // from ROM and buttons
  input  wire [1:0]  seq_val,
  input  wire        btn_valid,
  input  wire [1:0]  btn_val,

  // outputs to LEDs
  output reg  [3:0]  led,
  output reg         error_led,
  output reg [3:0]   rd_addr // this is the address of the ROM
);
  // FSM states
  localparam [2:0]
    S_INIT   = 3'd0,  // wait for start_play
    S_PLAY   = 3'd1,
    S_WAIT   = 3'd2,
    S_CHECK  = 3'd3,
    S_ERROR  = 3'd4;

  reg [2:0] state;
  reg [3:0] play_idx, input_idx, round_cnt;
  reg [1:0] latched_btn;

  always @(posedge clk_tick or posedge reset) begin
    if (reset) begin
      $display("[FSM DEBUG] @ T=%0t: In RESET block. State -> S_INIT.", $time);
      state      <= S_INIT;
      play_idx   <= 4'd0;
      input_idx  <= 4'd0;
      round_cnt  <= 4'd0;
      led        <= 4'd0;
      error_led  <= 1'b0;
      rd_addr    <= 4'd0;
    end else begin
      // This will print at every clock tick when not in reset
      $display("[FSM DEBUG] @ T=%0t: TICK! Current state=%d, start_play_input=%b, round_cnt=%d", $time, state, start_play, round_cnt);
      // defaults: turn off LEDs unless a state drives them
      led <= 4'd0;

      case (state)
      S_INIT: begin
        $display("[FSM DEBUG] @ T=%0t: In S_INIT block. Checking start_play...", $time);
        // wait until sequence_loader tells us the ROM is loaded
        if (start_play) begin
          $display("[FSM DEBUG] @ T=%0t: S_INIT sees start_play=1! New state->S_PLAY, new round_cnt->1.", $time);
          round_cnt <= 4'd1;  
          play_idx  <= 4'd0;
          rd_addr   <= 4'd0;
          state     <= S_PLAY;
        end
      end

      S_PLAY: begin
        if (play_idx < round_cnt) begin
          rd_addr   <= play_idx;
          // light the LED corresponding to seq_val
          led       <= 4'b0001 << seq_val;
          play_idx  <= play_idx + 1;
        end else begin
          // all steps shown → wait for user input
          input_idx <= 4'd0;
          rd_addr   <= 4'd0;
          state     <= S_WAIT;
        end
      end

      S_WAIT: begin
        // blank LEDs; latch when button pressed
        if (btn_valid) begin
          latched_btn <= btn_val;
          state       <= S_CHECK;
        end
      end

      S_CHECK: begin
        if (latched_btn == seq_val) begin // Correct button for current input_idx
          if (input_idx == round_cnt - 1) begin // Last input for this round was correct
            // Round complete → next round
            round_cnt <= round_cnt + 1;
            play_idx  <= 4'd0;
            // rd_addr will be set by S_PLAY based on new play_idx
            state     <= S_PLAY;
          end else begin
            // Correct input, but more inputs needed for this round
            input_idx <= input_idx + 1; // Advance to next input index
            rd_addr   <= input_idx + 1; // Point ROM to next value for S_WAIT/S_CHECK
            state     <= S_WAIT;
          end
        end else begin // Incorrect input
          error_led <= 1'b1;
          state     <= S_ERROR;
        end
      end

      S_ERROR: begin
        // show error until player presses any button, then restart
        if (btn_valid) begin
          error_led <= 1'b0;
          round_cnt <= 4'd1;
          play_idx  <= 4'd0;
          rd_addr   <= 4'd0;
          state     <= S_PLAY;
        end 
      end

      default: state <= S_INIT;
      endcase
    end
  end
endmodule