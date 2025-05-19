// clock_divider.v
// ----------------
// Divide 100 MHz → ~1 Hz for human-speed Simon playback.
//
// WIDTH=27 cuts 100e6 down to ~0.75 Hz on bit[26], so ~1.2 Hz refresh.
// Tweak WIDTH or BIT for exact rate.

module clock_divider #(
    parameter WIDTH = 27,
    parameter BIT   = 26
)(
    input  wire        clk,
    input  wire        reset,
    output wire        slow_clk
);
    reg [WIDTH-1:0] cnt;
    always @(posedge clk or posedge reset) begin
        if (reset)   cnt <= {WIDTH{1'b0}};
        else         cnt <= cnt + 1'b1;
    end
    assign slow_clk = cnt[BIT];
endmodule
