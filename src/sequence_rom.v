// sequence_rom.v
// --------------
// Drastically simplified for clock debugging
`timescale 1ns/1ps       // <- add this line

module sequence_rom #(
    parameter DEPTH = 10,
    parameter AW    = 4,
    parameter DW    = 2
)(
    input  wire           clk, // This is the clk we are testing
    // All other ports are temporarily unused for this test
    input  wire           write_en,
    input  wire [AW-1:0]  wr_addr,
    input  wire [DW-1:0]  wr_data,
    input  wire [AW-1:0]  rd_addr,
    output reg  [DW-1:0]  rd_data
);

    reg [DW-1:0] mem [0:DEPTH-1];
    reg [DW-1:0] next_rd_data; // For combinational read logic

    // Address range check
    wire wr_addr_valid = (wr_addr < DEPTH);
    wire rd_addr_valid = (rd_addr < DEPTH);

    // Initialize memory
    integer j;
    initial begin
        // $strobe("DUT: Initializing memory at time %0t", $time);
        for (j = 0; j < DEPTH; j = j + 1) begin
            mem[j] = {DW{1'b0}};
        end
        // $strobe("DUT: Memory initialized at time %0t", $time);
    end

    // Combinational logic for next read data value
    always @(*) begin
        // Default to X if no other condition met, helps catch issues
        next_rd_data = {DW{1'bx}};
        if (write_en && wr_addr_valid && (wr_addr == rd_addr)) begin
            next_rd_data = wr_data;  // Read-during-write (forwarding)
        end else if (rd_addr_valid) begin
            next_rd_data = mem[rd_addr];  // Normal read from memory
        end
        // $strobe("Time=%0t DUT COMB: we=%b, wa=%h, ra=%h -> next_rd_data=%h", 
        //         $time, write_en, wr_addr, rd_addr, next_rd_data);
    end

    // Synchronous (clocked) operations
    always @(posedge clk) begin
        // $strobe("Time=%0t DUT CLK_ENTRY: we=%b, wa=%h, wd=%h, ra=%h, calc_next_rd=%h",
        //         $time, write_en, wr_addr, wr_data, rd_addr, next_rd_data);

        // Write operation to memory
        if (write_en && wr_addr_valid) begin
            // TEMPORARY DEBUG CHANGE: Blocking assignment for mem write
            mem[wr_addr] <= wr_data; 
            // $strobe("Time=%0t DUT CLK_WRITE: mem[%h] <= %h", $time, wr_addr, wr_data);
        end

        // Register the read data
        rd_data <= next_rd_data;
        // $strobe("Time=%0t DUT CLK_RD_ASSIGN: rd_data gets %h (from next_rd_data)", $time, next_rd_data);
    end

endmodule
