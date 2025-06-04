// simon_fsm_hard.v
`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// Hard‑coded 4‑step Simon game, using two clocks:
//
//   • clk_tick  (btn_clk ≈ 100 Hz)   – drives the whole FSM
//   • LED_HOLD = 96                  – keeps each LED on ≈ 1 s
//
//   Fixes in this version
//   ---------------------
//   1.  Latches the button value in S_WAIT so S_CHECK compares
//       the *pressed* button, not a default 0.
//   2.  No other logic altered; timing/LED behaviour unchanged.
// -----------------------------------------------------------------------------
module simon_fsm_hard #(
    parameter N        = 10,    // length of hard‑coded sequence (changed from 4 to 10)
    parameter LED_HOLD = 96     // btn_clk cycles a colour stays lit
)(
    input  wire        clk_tick,
    input  wire        reset,

    // one‑shot button pulse (btn_valid=1 for 1 clk_tick)
    input  wire        btn_valid,
    input  wire [1:0]  btn_val,

    output reg  [3:0]  led,
    output reg         error_led,

    // debug
    output reg  [2:0]  state,
    output wire [3:0]  init_cnt
);
    // -------------------------------------------------------------------------
    // States
    // -------------------------------------------------------------------------
    localparam [2:0]
        S_INIT  = 3'd0,
        S_PLAY  = 3'd1,
        S_WAIT  = 3'd2,
        S_CHECK = 3'd3,
        S_ERROR = 3'd4;

    // hard‑coded pattern: 2,1,3,1,0,2,3,0,1,3 (10 elements)
    reg [1:0] sequence [0:N-1];
    initial begin
        sequence[0] = 2'd2; sequence[1] = 2'd1;
        sequence[2] = 2'd3; sequence[3] = 2'd1;
        sequence[4] = 2'd0; sequence[5] = 2'd2;
        sequence[6] = 2'd3; sequence[7] = 2'd0;
        sequence[8] = 2'd1; sequence[9] = 2'd3;
    end

    // counters & indices
    reg [3:0] init_idx, play_idx, input_idx, round_cnt;
    reg [6:0] hold_cnt;                // LED on‑time counter
    reg [1:0] latched_btn;             // *** NEW *** – stores player press

    assign init_cnt = init_idx;        // for seven‑segment display

    // -------------------------------------------------------------------------
    // Sequential FSM
    // -------------------------------------------------------------------------
    always @(posedge clk_tick or posedge reset) begin
        if (reset) begin
            // master reset -----------------------------------------------------
            state       <= S_INIT;
            init_idx    <= 0;
            play_idx    <= 0;
            input_idx   <= 0;
            round_cnt   <= 0;
            hold_cnt    <= 0;
            latched_btn <= 0;
            led         <= 0;
            error_led   <= 0;
        end
        else begin
            // ---------------------------------------------------------------
            case (state)
            // ------------------------------------------------- initial count
            S_INIT : begin
                if (init_idx < N)
                    init_idx <= init_idx + 1;            // 0‑4 for debug
                else begin
                    round_cnt <= 1;
                    play_idx  <= 0;
                    hold_cnt  <= 0;
                    state     <= S_PLAY;
                end
            end
            // ---------------------------------------------- play back LEDs
            S_PLAY : begin
                if (hold_cnt != 0) begin                 // keep LED lit
                    hold_cnt <= hold_cnt - 1;
                end
                else if (play_idx < round_cnt) begin
                    led      <= 4'b0001 << sequence[play_idx];
                    play_idx <= play_idx + 1;
                    hold_cnt <= LED_HOLD - 1;
                end
                else begin
                    led       <= 0;
                    input_idx <= 0;
                    state     <= S_WAIT;
                end
            end
            // ------------------------------------------- wait for player
            S_WAIT : begin
                led <= 0;
                if (btn_valid) begin
                    latched_btn <= btn_val;              // *** latch here ***
                    state       <= S_CHECK;
                end
            end
            // ------------------------------------------ check the press
            S_CHECK : begin
                if (latched_btn == sequence[input_idx]) begin
                    input_idx <= input_idx + 1;
                    //------------------------------------------------------
                    if (input_idx + 1 == round_cnt) begin
                        if (round_cnt < N) begin         // next round
                            round_cnt <= round_cnt + 1;
                            play_idx  <= 0;
                            hold_cnt  <= 0;
                            state     <= S_PLAY;
                        end else begin                   // game won -> reset
                            state <= S_INIT;
                        end
                    end else begin
                        state <= S_WAIT;                 // need next input
                    end
                end else begin
                    error_led <= 1;
                    led       <= 0;
                    state     <= S_ERROR;
                end
            end
            // ------------------------------------------------ error flash
            S_ERROR : begin
                led <= 0;
                if (btn_valid) begin                     // any press resets
                    error_led   <= 0;
                    round_cnt   <= 1;
                    play_idx    <= 0;
                    hold_cnt    <= 0;
                    state       <= S_PLAY;
                end
            end
            // -------------------------------------------------------------
            default: state <= S_INIT;
            endcase
        end // !reset
    end // always
endmodule
