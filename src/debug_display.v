// debug_display.v
// ----------------
// 4-bit → single-digit 7-segment, Basys-3 active-LOW.
// seg[0]=a, seg[1]=b, … seg[6]=g.  0 lights the segment.

`timescale 1ns/1ps
module debug_display(
    input  wire [3:0] hex,  // 0…F to display
    output reg  [6:0] seg,  // {a,b,c,d,e,f,g}, active-LOW
    output wire [3:0] an    // digit enables, active-LOW
);
  // Only digit 0 on:
  assign an = 4'b1110;

  always @(*) begin
    case (hex)
      4'h0: seg = 7'b1000000; // a–f on, g off
      4'h1: seg = 7'b1111001; //   b,c on
      4'h2: seg = 7'b0100100; // a,b  d,e  g
      4'h3: seg = 7'b0110000; // a,b,c,d   g
      4'h4: seg = 7'b0011001; //   b,c   f,g
      4'h5: seg = 7'b0010010; // a,  c,d, f,g
      4'h6: seg = 7'b0000010; // a,  c,d,e,f,g
      4'h7: seg = 7'b1111000; // a,b,c
      4'h8: seg = 7'b0000000; // all segments
      4'h9: seg = 7'b0010000; // a,b,c,d,  f,g
      4'hA: seg = 7'b0001000; // a,b,c,  e,f,g (A)
      4'hB: seg = 7'b0000011; //   c,d,e,f,g (b)
      4'hC: seg = 7'b1000110; // a,    d,e,f   (C)
      4'hD: seg = 7'b0100001; //   b,c,d,e,  g (d)
      4'hE: seg = 7'b0000110; // a,    d,e,f,g (E)
      4'hF: seg = 7'b0001110; // a,      e,f,g (F)
      default: seg = 7'b1111111; // blank
    endcase
  end
endmodule
