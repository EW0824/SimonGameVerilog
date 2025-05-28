// debug_display.v
// ----------------
// Direct active-LOW 4-bit→7-segment decoder + single-digit enable.
//   - seg[6:0]: 0 lights the segment.
//   - an[3:0]: 0 enables that digit (we only use digit0).

`timescale 1ns/1ps
module debug_display(
    input  wire [3:0] hex,      // value 0–F to show
    output reg  [6:0] seg,      // {a,b,c,d,e,f,g}, active-LOW
    output wire [3:0] an        // AN[3:0], active-LOW
);
    // only digit0
    assign an = 4'b1110;

    always @(*) begin
        case (hex)
            4'h0: seg = 7'b0000001; // 0 → a,b,c,d,e,f on; g off
            4'h1: seg = 7'b1001111; // 1 → b,c
            4'h2: seg = 7'b0010010; // 2 → a,b,d,e,g
            4'h3: seg = 7'b0000110; // 3 → a,b,c,d,g
            4'h4: seg = 7'b1001100; // 4 → b,c,f,g
            4'h5: seg = 7'b0100100; // 5 → a,c,d,f,g
            4'h6: seg = 7'b0100000; // 6 → a,c,d,e,f,g
            4'h7: seg = 7'b0001111; // 7 → a,b,c
            4'h8: seg = 7'b0000000; // 8 → all segments
            4'h9: seg = 7'b0000100; // 9 → a,b,c,d,f,g
            default: seg = 7'b1111111; // blank
        endcase
    end
endmodule
