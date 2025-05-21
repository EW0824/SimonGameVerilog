// debug_display.v  (updated for active-LOW Basys-3 segments)
// ----------------------------------------------------------
// - hex_to_7seg still produces active‐HIGH outputs (1 → on).
// - We invert them so that on Basys3 (active-LOW) a 0 lights the segment.
// - AN is already active‐LOW, and we keep only digit0 enabled.

`timescale 1ns/1ps

module hex_to_7seg (
    input  wire [3:0] hex,      // 0…F
    output reg  [6:0] segments  // {a,b,c,d,e,f,g}, active-HIGH
);
    always @(*) begin
        case (hex)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_0000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;
            default: segments = 7'b111_1111;
        endcase
    end
endmodule


module debug_display (
    input  wire [3:0] hex,      // nibble you want to watch
    output wire [6:0] seg,      // connect to SEG[6:0] (active-LOW)
    output wire [3:0] an        // connect to AN[3:0]  (active-LOW)
);
    // only light digit 0 (AN[0] = 0), others off
    assign an = 4'b1110;

    // raw active-HIGH pattern
    wire [6:0] raw_seg;
    hex_to_7seg u_hex2seg (
        .hex(hex),
        .segments(raw_seg)
    );

    // invert for active-LOW hardware
    assign seg = ~raw_seg;
endmodule
