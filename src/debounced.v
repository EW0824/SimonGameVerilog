// debounced.v  – debouncer for a single active‑high push‑button
module debounced #(parameter N = 19)(  // 2¹⁹ / 100 MHz ≈ 5 ms
    input  wire clk,   // 100 MHz
    input  wire rst,
    input  wire raw,   // mechanical contact
    output reg  q      // clean, debounced level
);
    reg [N-1:0] cnt = 0;
    reg state = 0;
    always @(posedge clk or posedge rst) begin
        if (rst) begin cnt<=0; state<=0; q<=0; end
        else begin
            if (raw==state) cnt<=0;
            else if (cnt==(1<<N)-1) begin
                state <= raw;
                q     <= raw;
                cnt   <= 0;
            end else cnt <= cnt + 1;
        end
    end
endmodule
