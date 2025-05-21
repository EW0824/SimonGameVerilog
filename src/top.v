// top.v
`timescale 1ns/1ps
module top(
    input  wire       clk,        // 100 MHz
    input  wire       reset,      // active-high
    input  wire [3:0] btn,        // one-hot inputs
    output wire [3:0] led,        // LD0–LD3
    output wire       error_led,  // LD4
    output wire [6:0] seg,        // seven-seg a–g (active-LOW)
    output wire [3:0] an          // seven-seg anodes (active-LOW)
);

    // interconnect wires
    wire        slow_clk;
    wire [1:0]  lfsr_val, seq_val;
    wire        btn_valid;
    wire [1:0]  btn_val;
    wire        write_en, lfsr_en;
    wire [3:0]  wr_addr, rd_addr;
    wire [1:0]  wr_data;
    wire [2:0]  fsm_state;
    wire [3:0]  init_cnt;

    // 1) slow clock ~1 Hz
    clock_divider clkdiv   (.clk(clk),    .reset(reset), .slow_clk(slow_clk));

    // 2) LFSR
    lfsr2        rng      (.clk(slow_clk), .reset(reset), .enable(lfsr_en), .q(lfsr_val));

    // 3) 4-deep sequence ROM
    sequence_rom #(.DEPTH(4)) rom (
      .clk      (slow_clk),
      .write_en (write_en),
      .wr_addr  (wr_addr),
      .wr_data  (wr_data),
      .rd_addr  (rd_addr),
      .rd_data  (seq_val)
    );

    // 4) button decoder
    button_decoder dec (
      .btn   (btn),
      .valid (btn_valid),
      .val   (btn_val)
    );

    // 5) FSM w/ N=4, export state & init_cnt
    simon_fsm #(.N(4)) fsm (
      .clk_tick     (slow_clk),
      .reset        (reset),
      .lfsr_val     (lfsr_val),
      .seq_val      (seq_val),
      .btn_valid    (btn_valid),
      .btn_val      (btn_val),
      .write_en     (write_en),
      .wr_addr      (wr_addr),
      .wr_data      (wr_data),
      .rd_addr      (rd_addr),
      .lfsr_enable  (lfsr_en),
      .led          (led),
      .error_led    (error_led),
      .state        (fsm_state),
      .init_cnt     (init_cnt)
    );

    // 6) Debug‐display mux:
    //    if INIT (state==0), show init_cnt (0–4); else show state.
    wire [3:0] debug_nibble = (fsm_state == 3'd0)
                              ? init_cnt
                              : {1'b0, fsm_state};

    debug_display dbg (
      .hex(debug_nibble),
      .seg(seg),
      .an (an )
    );
endmodule
