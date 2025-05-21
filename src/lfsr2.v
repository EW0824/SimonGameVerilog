// lfsr2.v
// --------
// A 2-bit maximal‐length Linear-Feedback Shift Register.
// 	•	State is a 2-bit register q.
// 	•	On each clock, if enable=1, you compute:
//  •   feedback = q[1] ^ q[0], q[1:0] = { q[0], feedback }
// 	•	That cycles through all non-zero 2-bit values: 01 → 10 → 11 → 01 
    
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
