// top.v
// ----------------
// Tie all modules together.

module top(
    input  wire       clk,        // 100 MHz
    input  wire       reset,
    input  wire [3:0] btn,        // one-hot
    output wire [3:0] led,
    output wire       error_led
    output wire [6:0] seg,  // connect to SEG[6:0]
    output wire [3:0] an    // connect to AN[3:0]
);
    // wires between modules
    wire       slow_clk;
    wire [1:0] lfsr_val;
    wire [1:0] seq_val;
    wire       btn_valid;
    wire [1:0] btn_val;
    wire       write_en;
    wire [3:0] wr_addr, rd_addr;
    wire [1:0] wr_data;
    wire       lfsr_en;
    wire [2:0] fsm_state;   // debug: current FSM state

    // 1) slow clock
    clock_divider clkdiv (
      .clk(clk), .reset(reset), .slow_clk(slow_clk)
    );

    // 2) LFSR (enabled only during INIT)
    lfsr2 rng (
      .clk(slow_clk),
      .reset(reset),
      .enable(lfsr_en),
      .q(lfsr_val)
    );

    // 3) Sequence ROM
    sequence_rom #(.DEPTH(10)) rom (
      .clk(slow_clk),
      .write_en(write_en),
      .wr_addr(wr_addr),
      .wr_data(wr_data),
      .rd_addr(rd_addr),
      .rd_data(seq_val)
    );

    // 4) Button decoder
    button_decoder dec (
      .btn(btn),
      .valid(btn_valid),
      .val(btn_val)
    );

    // 5) FSM
    simon_fsm fsm (
      .clk_tick(slow_clk),
      .reset(reset),
      .lfsr_val(lfsr_val),
      .seq_val(seq_val),
      .btn_valid(btn_valid),
      .btn_val(btn_val),
      .write_en(write_en),
      .wr_addr(wr_addr),
      .wr_data(wr_data),
      .rd_addr(rd_addr),
      .lfsr_enable(lfsr_en),
      .led(led),
      .error_led(error_led),
      .state(fsm_state) 
    );

    // 6) Debug display
    debug_display dbg (
      .hex ( {1'b0, fsm_state} ),  // pad to 4 bits
      .seg ( seg     ),
      .an  ( an      )
    );
endmodule