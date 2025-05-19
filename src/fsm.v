
// fsm.v
// --------
// INIT -> PLAY -> WAIT -> CHECK -> ERROR
// Generate control signals for ROM write&reads, drives LEDs

module fsm #(
    parameter N = 10,
) (
    input wire clk_tick, // ~1 Hz
    input wire reset,
    input wire start_play, // high when sequence_loader is done

    // from ROM & buttons
    input wire [1:0] seq_val,
    input wire btn_valid,
    input wire [1:0] btn_val,

    // outputs to LEDs
    output reg [3:0] led,
    output reg error_led
);

    // FSM states
    localparam [2:0]
        S_INIT = 3'd0;
        S_PLAY = 3'd1;
        S_WAIT = 3'd2;
        S_CHECK = 3'd3;
        S_ERROR = 3'd4;

    reg [2:0] state;
    reg [3:0] play_idx, input_idx, round_cnt;
    reg [1:0] latched_btn;
    reg [3:0] rd_addr; // feeding this to sequence_rom rd_addr port

    always @(posedge clk_tick or posedge reset) begin
        if (reset) begin
            state <= S_INIT;
            play_idx <= 4'd0;
            input_idx <= 4'd0;
            round_cnt <= 4'd0;
            rd_addr <= 4'd0;
            led <= 4'd0;
            error_led <= 1'b0;
        end else begin 
            // defaults: turn off LEDs unless a state drives them
            led <= 4'd0;

            case (state)
            S_INIT: begin
                // wait until sequence_loader tells us ROM is loaded
                if (start_play) begin
                    state <= S_PLAY;
                    play_idx <= 4'd0;
                    round_cnt <= 4'd0;
                end
            end

            S_PLAY: begin
                if (play_idx < round_cnt) begim
                    rd_addr <= play_idx;
                    // light the LED corresponding to seq_val
                    led <= 4'b0001 << seq_val;
                    play_idx <= play_idx + 1;
                end else begin
                    // wait for button press
                    input_idx <= 4'd0;
                    state <= S_WAIT;
                end   
            end 

            S_WAIT: begin
                // blank LEDs; latch when button pressed
                if (btn_valid) begin
                    latched_btn <= btn_val;
                    state <= S_CHECK;
                end
            end

            S_CHECK: begin
                // correct? either advance or error
                if (latched_btn == seq_val) begin
                    input_idx <= input_idx + 1;
                    if (input_idx + 1 == round_cnt) begin
                        // round complete -> next round
                        round_cnt <= round_cnt + 1;
                        play_idx <= 4'd0;
                        state <= S_PLAY;
                    end else begin 
                        state <= S_WAIT;
                    end
                end else begin
                    // incorrect -> error
                    state <= S_ERROR;
                    error_led <= 1'b1;
                end
            end

            S_ERROR: begin
                // show error until player presses any button => then restart
                if (btn_valid) begin
                    error_led <= 1'b0;
                    round_cnt <= 4'd1;
                    play_idx <= 4'd0;
                    state <= S_PLAY;
                end
            end

            default: state <= S_INIT;
            endcase
        end
    end
endmodule