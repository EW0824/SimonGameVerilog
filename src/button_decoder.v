// button_decoder.v
// ----------------
// Turns a one-hot 4-bit `btn` into (`valid`, value[1:0]).

module button_decoder (
    input  wire [3:0] btn,
    output reg        valid,
    output reg [1:0]  val
);
    always @(*) begin
        case (btn)
            4'b0001: begin valid = 1; val = 2'd0; end
            4'b0010: begin valid = 1; val = 2'd1; end
            4'b0100: begin valid = 1; val = 2'd2; end
            4'b1000: begin valid = 1; val = 2'd3; end
            default: begin valid = 0; val = 2'd0; end
        endcase
    end
endmodule