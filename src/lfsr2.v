// lfsr2.v
// -------
// 2-bit LFSR: taps on bit1⊕bit0 → new bit.
// Advance only when `enable` is high on slow_clk.

module lfsr2 (
    input  wire       clk,      // slow clock
    input  wire       reset,
    input  wire       enable,
    output reg [1:0]  q
);
    always @(posedge clk or posedge reset) begin
        if (reset)        q <= 2'b10;  
        else if (enable)  q <= { q[0], q[1] ^ q[0] };
    end
endmodule
