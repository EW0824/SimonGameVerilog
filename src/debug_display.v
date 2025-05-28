// debug_display.v  (fixed hex→7seg patterns for Basys-3)
// ------------------------------------------------------
//
// hex_to_7seg: 4-bit → 7-segment (a–g) pattern, active-HIGH
// debug_display: inverts for active-LOW hardware, drives only digit0.

`timescale 1ns/1ps

module hex_to_7seg (
    input  wire [3:0] hex,      // 0…F
    output reg  [6:0] segments  // {a,b,c,d,e,f,g}, active-HIGH
);
    always @(*) begin
        case (hex)
            4'h0: segments = 7'b1111110; // a,b,c,d,e,f on; g off
            4'h1: segments = 7'b0110000; //     b,c on
            4'h2: segments = 7'b1101101; // a,b,  d,e,  g on
            4'h3: segments = 7'b1111001; // a,b,c,d,     g on
            4'h4: segments = 7'b0110011; //   b,c,    f, g on
            4'h5: segments = 7'b1011011; // a,  c,d, f, g on
            4'h6: segments = 7'b1011111; // a,  c,d,e,f,g on
            4'h7: segments = 7'b1110000; // a,b,c on
            4'h8: segments = 7'b1111111; // all on
            4'h9: segments = 7'b1111011; // a,b,c,d,  f,g on
            4'hA: segments = 7'b1110111; // a,b,c,  e,f,g on (A)
            4'hB: segments = 7'b0011111; //     c,d,e,f,g on (b)
            4'hC: segments = 7'b1001110; // a,    d,e,f on (C)
            4'hD: segments = 7'b0111101; //   b,c,d,e,  g on (d)
            4'hE: segments = 7'b1001111; // a,    d,e,f,g on (E)
            4'hF: segments = 7'b1000111; // a,       e,f,g on (F)
            default: segments = 7'b0000000; // all off
        endcase
    end
endmodule


module debug_display (
    input  wire [3:0] hex,      // nibble you want to watch
    output wire [6:0] seg,      // connect to SEG[6:0] (active-LOW)
    output wire [3:0] an        // connect to AN[3:0]  (active-LOW)
);
    // only light digit0 (active-LOW)
    assign an = 4'b1110;

    // get active-HIGH pattern, then invert for real hardware
    wire [6:0] raw_seg;
    hex_to_7seg u_hex2seg (
        .hex     (hex),
        .segments(raw_seg)
    );

    assign seg = ~raw_seg;
endmodule
