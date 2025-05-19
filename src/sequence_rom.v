// sequence_rom.v
// --------------
// Simple 10-deep, 2-bit wide dual-port RAM.
// Synchronous write & read on the same clock.

module sequence_rom #(
    parameter DEPTH = 10,
    parameter AW    = 4,   // to index up to 2^4=16
    parameter DW    = 2
)(
    input  wire           clk,
    // write port
    input  wire           write_en,
    input  wire [AW-1:0]  wr_addr,
    input  wire [DW-1:0]  wr_data,
    // read port
    input  wire [AW-1:0]  rd_addr,
    output reg  [DW-1:0]  rd_data
);
    reg [DW-1:0] mem [0:DEPTH-1];

    always @(posedge clk) begin
        if (write_en)
            mem[wr_addr] <= wr_data;
        rd_data <= mem[rd_addr];
    end
endmodule
