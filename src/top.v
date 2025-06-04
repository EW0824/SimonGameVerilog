`timescale 1ns/1ps
module top(
    input  wire       clk,        // 100 MHz
    input  wire       reset,      // active-high
    input  wire [3:0] btn,        // BTNU, BTNL, BTNR, BTND (active-high)
    output wire [3:0] led,        // LD0–LD3
    output wire       error_led,  // LD4
    output wire [6:0] seg,        // 7-seg a–g (active-LOW)
    output wire [3:0] an          // 7-seg anodes (active-LOW)
);

  //=== clocks, LFSR, ROM & FSM wires ===
  wire        slow_clk;
  wire [1:0]  lfsr_val, seq_val;
  wire        btn_valid;
  wire [1:0]  btn_val;
  wire        write_en;
  wire        lfsr_en = 1'b1;
  wire [3:0]  wr_addr, rd_addr;
  wire [1:0]  wr_data;
  wire [2:0]  fsm_state;
  wire [3:0]  init_cnt;

  // slow ~1 Hz tick
  clock_divider clkdiv (
    .clk      (clk),
    .reset    (reset),
    .slow_clk (slow_clk)
  );

  // pseudo-random 2-bit LFSR
  // lfsr2 rng (
  //   .clk    (slow_clk),
  //   .reset  (reset),
  //   .enable (lfsr_en),
  //   .q      (lfsr_val)
  // );

  // 4-entry sequence ROM
  sequence_rom #(.DEPTH(4)) rom (
    .clk      (slow_clk),
    // .write_en (1'b0),           // ROM is read-only in hardcoded mode
    // .wr_addr  (4'b0),           // Tie off unused write address
    // .wr_data  (2'b0),           // Tie off unused write data
    .rd_addr  (4'b0),           // Tie off read address since we're not using ROM
    .rd_data  (seq_val)         // This will be unused but properly connected
  );


  // // --- Switch synchroniser + 1-shot pulse generator ---
  // reg  [3:0] sw_ff  = 4'b0;       // sync
  // reg  [3:0] sw_ff2 = 4'b0;       // for edge detect
  // wire [3:0] sw_rise =  sw_ff & ~sw_ff2;   // 1 on rising edge

  // always @(posedge slow_clk or posedge reset) begin
  //     if (reset) begin
  //         sw_ff  <= 4'b0;
  //         sw_ff2 <= 4'b0;
  //     end else begin
  //         sw_ff  <= sw;       // two-stage synchroniser
  //         sw_ff2 <= sw_ff;
  //     end
  // end

  // // Priority encoder: lowest-numbered switch wins
  // reg       btn_valid_r;
  // reg [1:0] btn_val_r;
  // always @(*) begin
  //     casex (sw_rise)
  //         4'b0001: begin btn_valid_r = 1'b1; btn_val_r = 2'd0; end
  //         4'b0010: begin btn_valid_r = 1'b1; btn_val_r = 2'd1; end
  //         4'b0100: begin btn_valid_r = 1'b1; btn_val_r = 2'd2; end
  //         4'b1000: begin btn_valid_r = 1'b1; btn_val_r = 2'd3; end
  //         default: begin btn_valid_r = 1'b0; btn_val_r = 2'd0; end
  //     endcase
  // end

  // assign btn_valid = btn_valid_r;
  // assign btn_val   = btn_val_r;

  // ------------------------------------------------------------------
  // Push-button synchroniser + 1-shot pulse (valid for 1 slow_clk tick)
  // ------------------------------------------------------------------
  reg  [3:0] btn_ff  = 4'b0;   // stage-1 sync
  reg  [3:0] btn_ff2 = 4'b0;   // stage-2 sync
  wire [3:0] btn_rise =  btn_ff & ~btn_ff2;   // detect 0→1 edge

  always @(posedge slow_clk or posedge reset) begin
      if (reset) begin
          btn_ff  <= 4'b0;
          btn_ff2 <= 4'b0;
      end else begin
          btn_ff  <= btn;      // two-stage sync into slow_clk domain
          btn_ff2 <= btn_ff;
      end
  end

  // Priority encoder: lowest-numbered button wins if two are pressed
  reg       btn_valid_r;
  reg [1:0] btn_val_r;
  always @(*) begin
      casex (btn_rise)
          4'b0001: begin btn_valid_r = 1'b1; btn_val_r = 2'd0; end   // BTNU
          4'b0010: begin btn_valid_r = 1'b1; btn_val_r = 2'd1; end   // BTNL
          4'b0100: begin btn_valid_r = 1'b1; btn_val_r = 2'd2; end   // BTNR
          4'b1000: begin btn_valid_r = 1'b1; btn_val_r = 2'd3; end   // BTND
          default: begin btn_valid_r = 1'b0; btn_val_r = 2'd0; end
      endcase
  end

  assign btn_valid = btn_valid_r;
  assign btn_val   = btn_val_r;
  

  // 5) main FSM → use hardcoded variant
  simon_fsm_hard #(.N(4)) fsm (
    .clk_tick  (slow_clk),
    .reset     (reset),
    .btn_valid (btn_valid),
    .btn_val   (btn_val),
    .led       (led),
    .error_led (error_led),
    .state     (fsm_state),
    .init_cnt  (init_cnt)
  );

  // debug: show INIT count 0–4, then FSM state 1–4
  wire [3:0] debug_nibble = (fsm_state == 3'd0)
                            ? init_cnt
                            : {1'b0, fsm_state};
  debug_display dbg (
    .hex(debug_nibble),
    .seg(seg),
    .an (an )
  );
endmodule
