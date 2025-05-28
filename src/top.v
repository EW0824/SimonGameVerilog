// top.v
// ----------------
// Simon game top with switch edge‐detect and debug_display.

`timescale 1ns/1ps
module top(
    input  wire       clk,        // 100 MHz
    input  wire       reset,      // active-high
    input  wire [3:0] btn,        // SW[3:0] as one-hot
    output wire [3:0] led,        // LD0–LD3
    output wire       error_led,  // LD4
    output wire [6:0] seg,        // 7-seg a–g (active-LOW)
    output wire [3:0] an          // 7-seg anodes (active-LOW)
);

  //=== slow clock & LFSR & ROM & FSM wires ===
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
  clock_divider clkdiv (
    .clk      (clk),
    .reset    (reset),
    .slow_clk (slow_clk)
  );

  // 2) LFSR
  lfsr2 rng (
    .clk    (slow_clk),
    .reset  (reset),
    .enable (lfsr_en),
    .q      (lfsr_val)
  );

  // 3) 4-entry sequence ROM
  sequence_rom #(.DEPTH(4)) rom (
    .clk      (slow_clk),
    .write_en (write_en),
    .wr_addr  (wr_addr),
    .wr_data  (wr_data),
    .rd_addr  (rd_addr),
    .rd_data  (seq_val)
  );

  //=== switch synchronizer + rising-edge detector ===
  reg [3:0] sw0, sw1, sw_prev;
  wire [3:0] sw_rise = sw1 & ~sw_prev;

  always @(posedge slow_clk or posedge reset) begin
    if (reset) begin
      sw0     <= 4'd0;
      sw1     <= 4'd0;
      sw_prev <= 4'd0;
    end else begin
      sw0     <= btn;    // sample
      sw1     <= sw0;    // synchronize
      sw_prev <= sw1;    // keep last cycle
    end
  end

  // 4) button decoder now sees only the one-shot pulses
  button_decoder dec (
    .btn   (sw_rise),
    .valid (btn_valid),
    .val   (btn_val)
  );

  // 5) main FSM (N=4) with debug ports
  simon_fsm #(.N(4)) fsm (
    .clk_tick    (slow_clk),
    .reset       (reset),
    .lfsr_val    (lfsr_val),
    .seq_val     (seq_val),
    .btn_valid   (btn_valid),
    .btn_val     (btn_val),
    .write_en    (write_en),
    .wr_addr     (wr_addr),
    .wr_data     (wr_data),
    .rd_addr     (rd_addr),
    .lfsr_enable (lfsr_en),
    .led         (led),
    .error_led   (error_led),
    .state       (fsm_state),
    .init_cnt    (init_cnt)
  );

  // 6) debug_display: show INIT count 0–4, then FSM state 1–4
  wire [3:0] debug_nibble = (fsm_state == 3'd0)
                            ? init_cnt
                            : {1'b0, fsm_state};

  debug_display dbg (
    .hex(debug_nibble),
    .seg(seg),
    .an (an )
  );

endmodule
