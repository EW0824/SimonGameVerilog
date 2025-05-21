// simon_fsm.v
// -----------
// The heart of the game: INIT → PLAY → WAIT → CHECK → ERROR.
// Generates control signals for ROM writes & reads, drives LEDs.

module simon_fsm #(
    parameter N = 10
)(
    input  wire        clk_tick,    // ~1 Hz
    input  wire        reset,
    // from LFSR
    input  wire [1:0]  lfsr_val,
    // from ROM
    input  wire [1:0]  seq_val,
    // from button_decoder
    input  wire        btn_valid,
    input  wire [1:0]  btn_val,

    // → sequence_rom
    output reg         write_en,
    output reg  [3:0]  wr_addr,
    output reg  [1:0]  wr_data,
    output reg  [3:0]  rd_addr,

    // → lfsr2 enable
    output reg         lfsr_enable,

    // → top LEDs
    output reg  [3:0]  led,
    output reg         error_led
);
    // FSM states
    localparam [2:0]
      S_INIT   = 3'd0,
      S_PLAY   = 3'd1,
      S_WAIT   = 3'd2,
      S_CHECK  = 3'd3,
      S_ERROR  = 3'd4;

    reg [2:0] state;
    reg [3:0] init_idx, play_idx, input_idx, round_cnt;
    reg [1:0] latched_btn;

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
      end else begin
        // defaults
        write_en    <= 1'b0;
        lfsr_enable <= 1'b0;

        case (state)
        S_INIT: begin
          if (init_idx < N) begin
            // write next LFSR value into ROM
            write_en     <= 1;
            lfsr_enable  <= 1;
            wr_addr      <= init_idx;
            wr_data      <= lfsr_val;
            init_idx     <= init_idx + 1;
          end else begin
            // done → start round 1
            round_cnt <= 4'd1;
            play_idx  <= 4'd0;
            state     <= S_PLAY;
          end
        end

        S_PLAY: begin
          if (play_idx < round_cnt) begin
            rd_addr <= play_idx;
            // light one-hot LED
            led     <= 4'b0001 << seq_val;
            play_idx<= play_idx + 1;
          end else begin
            led       <= 4'd0;
            input_idx <= 4'd0;
            state     <= S_WAIT;
          end
        end

        S_WAIT: begin
          led <= 4'd0;
          if (btn_valid) begin
            latched_btn <= btn_val;
            state       <= S_CHECK;
          end
        end

        S_CHECK: begin
          led <= 4'd0;
          // compare
          if (latched_btn == seq_val) begin
            input_idx <= input_idx + 1;
            if (input_idx + 1 == round_cnt) begin
              // finished current round
              round_cnt <= round_cnt + 1;
              play_idx  <= 4'd0;
              state     <= S_PLAY;
            end else begin
              state <= S_WAIT;
            end
          end else begin
            error_led <= 1'b1;
            state     <= S_ERROR;
          end
        end

        S_ERROR: begin
          if (btn_valid) begin
            error_led <= 1'b0;
            round_cnt <= 4'd1;
            play_idx  <= 4'd0;
            state     <= S_PLAY;
          end
        end

        default: state <= S_INIT;
        endcase
      end
    end
endmodule
