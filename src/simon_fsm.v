`timescale 1ns / 1ps
// simon_fsm.v
module simon_fsm #(
    parameter N = 10          // default, override in top
)(
    input  wire         clk_tick,
    input  wire         reset,
    input  wire  [1:0]  lfsr_val,
    input  wire  [1:0]  seq_val,
    input  wire         btn_valid,
    input  wire  [1:0]  btn_val,

    // → sequence_rom
    output reg          write_en,
    output reg   [3:0]  wr_addr,
    output reg   [1:0]  wr_data,
    output reg   [3:0]  rd_addr,

    // → lfsr2
    output reg          lfsr_enable,

    // → LEDs
    output reg   [3:0]  led,
    output reg          error_led,

    // debug ports
    output reg   [2:0]  state,
    output      [3:0]   init_cnt    // how many ROM entries have been written
);

    localparam [2:0]
      S_INIT  = 3'd0,
      S_PLAY  = 3'd1,
      S_WAIT  = 3'd2,
      S_CHECK = 3'd3,
      S_ERROR = 3'd4;

    reg [3:0] init_idx, play_idx, input_idx, round_cnt;
    reg [1:0] latched_btn;
    reg       display_done;  // Flag for sequence display completion
    reg       btn_processed; // Flag to ensure button is processed only once
    reg [3:0] led_timer;    // Timer for LED display

    // expose init_idx
    assign init_cnt = init_idx;

    always @(posedge clk_tick or posedge reset) begin
      if (reset) begin
        state        <= S_INIT;
        init_idx     <= 4'd0;
        play_idx     <= 4'd0;
        input_idx    <= 4'd0;
        round_cnt    <= 4'd0;
        write_en     <= 1'b0;
        lfsr_enable  <= 1'b0;
        led          <= 4'd0;
        error_led    <= 1'b0;
        wr_addr      <= 4'd0;
        wr_data      <= 2'd0;
        rd_addr      <= 4'd0;
        latched_btn  <= 2'd0;
        display_done <= 1'b0;
        btn_processed <= 1'b0;
        led_timer    <= 4'd0;
      end else begin
        // defaults
        write_en    <= 1'b0;
        lfsr_enable <= 1'b0;

        // LED timer logic
        if (led_timer > 0) begin
            led_timer <= led_timer - 1;
        end else begin
            led <= 4'd0;  // Turn off LEDs when timer expires
        end

        case (state)
          S_INIT: begin
            if (init_idx < N) begin
              // load one more LFSR value into ROM
              write_en    <= 1;
              lfsr_enable <= 1;
              wr_addr     <= init_idx;
              wr_data     <= lfsr_val;
              init_idx    <= init_idx + 1;
            end else begin
              // finished loading → go to round 1
              round_cnt    <= 4'd1;
              play_idx     <= 4'd0;
              rd_addr      <= 4'd0;
              display_done <= 1'b0;
              state        <= S_PLAY;
            end
          end

          S_PLAY: begin
            if (!display_done) begin
              if (play_idx < round_cnt) begin
                rd_addr <= play_idx;
                if (led_timer == 0) begin  // Only update LED pattern when timer expires
                    led <= 4'b0001 << seq_val;
                    led_timer <= 4'd8;  // Set LED display time
                    play_idx <= play_idx + 1;
                end
              end else begin
                led          <= 4'd0;
                input_idx    <= 4'd0;
                rd_addr      <= 4'd0;  // Always start from beginning for input checking
                display_done <= 1'b1;
                btn_processed <= 1'b0;
                state        <= S_WAIT;
              end
            end
          end

          S_WAIT: begin
            if (btn_valid && !btn_processed) begin
              latched_btn <= btn_val;
              btn_processed <= 1'b1;
              state <= S_CHECK;
            end else if (!btn_valid && btn_processed) begin
              // Reset btn_processed only when button is released
              btn_processed <= 1'b0;
            end
          end

          S_CHECK: begin
            if (latched_btn == seq_val) begin  // Compare with current seq_val at rd_addr
              input_idx <= input_idx + 1;
              if (input_idx + 1 == round_cnt) begin
                // Round complete, advance to next round
                round_cnt    <= round_cnt + 1;
                play_idx     <= 4'd0;
                rd_addr      <= 4'd0;
                display_done <= 1'b0;
                state        <= S_PLAY;
              end else begin
                // More inputs needed for this round
                rd_addr      <= input_idx + 1;  // Point to next expected input
                state        <= S_WAIT;
              end
            end else begin
              error_led <= 1'b1;
              state     <= S_ERROR;
            end
          end

          S_ERROR: begin
            if (btn_valid) begin
              error_led    <= 1'b0;
              round_cnt    <= 4'd1;
              play_idx     <= 4'd0;
              input_idx    <= 4'd0;
              rd_addr      <= 4'd0;
              display_done <= 1'b0;
              btn_processed <= 1'b0;
              state        <= S_PLAY;
            end
          end

          default: state <= S_INIT;
        endcase
      end
    end
endmodule
