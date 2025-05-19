// sequence_loader.v
// --------
// Pumps N random values into seq ROM, then asserts "done".

module sequence_loader #(
    parameter N = 10,
) (
    input wire clk,
    input wire reset,
    input wire[1:0] lfsr_val,
    output reg write_en,
    output reg [3:0] wr_addr,
    output reg [1:0] wr_data,
    output reg lfsr_enable,
    output reg done
    
);

    reg [3:0] init_idx;

    always @(posedge clk_tick or posedge reset) begin
        if (reset) begin
            init_idx <= 4'd0;
            write_en <= 1'b0;
            lfsr_enable <= 1'b0;
            done <= 1'b0;
        end else if (!done) begin
            if (init_idx < N) begin
                // drive one ROM write per tick
                write_en <= 1'b1;
                lfsr_enable <= 1'b1;
                wr_addr <= init_idx;
                wr_data <= lfsr_val;
                init_idx <= init_idx + 1;
            end else begin
                // finished loading
                write_en <= 1'b0;
                lfsr_enable <= 1'b0;
                done <= 1'b1;
            end
        end
    end
endmodule