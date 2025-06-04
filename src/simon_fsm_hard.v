// simon_fsm_hard.v
`timescale 1ns/1ps
module simon_fsm_hard #(
    parameter N = 4          // hard-coded 4-step game
)(
    input  wire        clk_tick,
    input  wire        reset,
    input  wire        btn_valid,
    input  wire [1:0]  btn_val,

    output reg  [3:0]  led,
    output reg         error_led,

    // debug
    output reg  [2:0]  state,
    output     [3:0]   init_cnt  // will just count 0→4 then stick at 4
);
    reg [2:0] hold_cnt;   // 0‑7 => LED‑on time ≈ (hold_cnt+1)/btn_clk

    // states
    localparam [2:0]
      S_INIT  = 3'd0,
      S_PLAY  = 3'd1,
      S_WAIT  = 3'd2,
      S_CHECK = 3'd3,
      S_ERROR = 3'd4;

    // hard-coded sequence: 0→1→2→3
    reg [1:0] sequence [0:N-1];
    initial begin
      sequence[0] = 2'd0;
      sequence[1] = 2'd1;
      sequence[2] = 2'd2;
      sequence[3] = 2'd3;
    end

    reg [3:0] init_idx, play_idx, input_idx, round_cnt;
    wire [1:0] seq_val = sequence[play_idx];
    assign init_cnt = init_idx;

    // Debug signals
    wire play_idx_lt_round = (play_idx < round_cnt);
    wire [3:0] next_play_idx = play_idx + 1;

    always @(posedge clk_tick or posedge reset) begin
      if (reset) begin
        state     <= S_INIT;
        init_idx  <= 4'd0;
        play_idx  <= 4'd0;
        input_idx <= 4'd0;
        round_cnt <= 4'd0;
        led       <= 4'b0000;
        error_led <= 1'b0;
      end else begin
        case(state)
          S_INIT: begin
            // just count 0→4 on debug, no ROM
            if (init_idx < N) init_idx <= init_idx + 1;
            else begin
              round_cnt <= 4'd1;
              play_idx  <= 4'd0;
              state     <= S_PLAY;
            end
          end

          S_PLAY : begin
            if (hold_cnt != 0) begin
              hold_cnt <= hold_cnt - 1;          // keep LED on
            end else if (play_idx < round_cnt) begin
              led      <= 4'b0001 << sequence[play_idx];
              play_idx <= play_idx + 1;
              hold_cnt <= 3'd5;                  // ~60 ms at 96 Hz
            end else begin
              led       <= 4'd0;
              input_idx <= 0;
              state     <= S_WAIT;
            end
          end

          S_WAIT: begin
            // Keep LED off while waiting
            led <= 4'b0000;
            // Check for button press
            if (btn_valid) begin
              state <= S_CHECK;
            end
          end

          S_CHECK : begin
    if (btn_val == sequence[input_idx]) begin
        input_idx <= input_idx + 1;
        if (input_idx + 1 == round_cnt) begin
            if (round_cnt < N) begin        // NEW bound check
                round_cnt <= round_cnt + 1;
                play_idx  <= 0;
                state     <= S_PLAY;
            end else begin                  // reached 4, game won
                state <= S_INIT;            // or make a WIN state
            end
        end else begin
            state <= S_WAIT;
        end
    end else begin
        error_led <= 1;
        state     <= S_ERROR;
    end
          end


          S_ERROR: begin
            if (btn_valid) begin
              // Reset on any button press
              error_led <= 1'b0;
              round_cnt <= 4'd1;
              play_idx <= 4'd0;
              state <= S_PLAY;
            end
          end
        endcase
      end
    end
endmodule
