// simon_fsm_hard.v
`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// Hard‑coded 4‑step Simon FSM, tuned for two‑clock design:
//
//   • btn_clk  ≈ 100 Hz   → runs the whole FSM & button checking
//   • LED_HOLD counter   → keeps each LED/state visible ≈ 1 s
//
// Only this file changed; all other modules remain as‑is.
// -----------------------------------------------------------------------------
module simon_fsm_hard #(
    parameter N         = 4,     // fixed‑length sequence
    parameter LED_HOLD  = 96     // btn_clk cycles a colour stays lit (≈1 s @96 Hz)
)(
    input  wire        clk_tick,     // (= btn_clk)
    input  wire        reset,

    // button interface (level‑one‑shot produced in top.v)
    input  wire        btn_valid,
    input  wire [1:0]  btn_val,

    // outputs
    output reg  [3:0]  led,
    output reg         error_led,

    // debug
    output reg  [2:0]  state,
    output wire [3:0]  init_cnt
);
    // -------------------------------------------------------------------------
    // State machine                                                                          
    // -------------------------------------------------------------------------
    localparam [2:0]
        S_INIT  = 3'd0,
        S_PLAY  = 3'd1,
        S_WAIT  = 3'd2,
        S_CHECK = 3'd3,
        S_ERROR = 3'd4;

    // hard‑coded pattern 0‑1‑2‑3
    reg [1:0] sequence [0:N-1];
    initial begin
        sequence[0] = 2'd0; sequence[1] = 2'd1;
        sequence[2] = 2'd2; sequence[3] = 2'd3;
    end

    // counters & indices
    reg  [3:0] init_idx, play_idx, input_idx, round_cnt;
    reg  [6:0] hold_cnt;           // 7 bits ≥ LED_HOLD‑1 (≤127)

    assign init_cnt = init_idx;    // for seven‑seg display

    // -------------------------------------------------------------------------
    // Sequential logic
    // -------------------------------------------------------------------------
    always @(posedge clk_tick or posedge reset) begin
        if (reset) begin
            // master reset -----------------------------------------------------
            state      <= S_INIT;
            init_idx   <= 0;
            play_idx   <= 0;
            input_idx  <= 0;
            round_cnt  <= 0;
            hold_cnt   <= 0;
            led        <= 0;
            error_led  <= 0;
        end else begin
            //------------------------------------------------------------------
            case (state)
            // -------------------------------------------------- ROM priming ---
            S_INIT: begin
                if (init_idx < N)
                    init_idx <= init_idx + 1;          // counts 0→4 for debug
                else begin
                    round_cnt <= 1;                    // start with 1 colour
                    play_idx  <= 0;
                    hold_cnt  <= 0;                    // force immediate LED
                    state     <= S_PLAY;
                end
            end
            // ------------------------------------------- play‑back sequence ---
            S_PLAY: begin
                if (hold_cnt != 0) begin
                    hold_cnt <= hold_cnt - 1;          // keep LED on
                end
                else if (play_idx < round_cnt) begin
                    led      <= 4'b0001 << sequence[play_idx];
                    play_idx <= play_idx + 1;
                    hold_cnt <= LED_HOLD - 1;          // reload counter
                end
                else begin
                    led       <= 4'd0;                 // blank between rounds
                    input_idx <= 0;
                    state     <= S_WAIT;
                end
            end
            // --------------------------------------------- wait for player ---
            S_WAIT: begin
                led <= 4'd0;
                if (btn_valid)
                    state <= S_CHECK;
            end
            // ----------------------------------------- check player input ---
            S_CHECK: begin
                if (btn_val == sequence[input_idx]) begin
                    input_idx <= input_idx + 1;
                    if (input_idx + 1 == round_cnt) begin
                        // round finished
                        if (round_cnt < N) begin
                            round_cnt <= round_cnt + 1;
                            play_idx  <= 0;
                            hold_cnt  <= 0;
                            state     <= S_PLAY;
                        end else begin
                            state <= S_INIT;           // whole game won
                        end
                    end else begin
                        state <= S_WAIT;               // need more inputs
                    end
                end else begin
                    error_led <= 1;
                    led       <= 0;
                    state     <= S_ERROR;
                end
            end
            // ------------------------------------------------- error state ---
            S_ERROR: begin
                led <= 0;                             // keep LEDs off
                if (btn_valid) begin
                    error_led <= 0;
                    round_cnt <= 1;
                    play_idx  <= 0;
                    hold_cnt  <= 0;
                    state     <= S_PLAY;              // restart from round 1
                end
            end
            // -----------------------------------------------------------------
            default: state <= S_INIT;
            endcase
            //------------------------------------------------------------------
        end // !reset
    end // always
endmodule
