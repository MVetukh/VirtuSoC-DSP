// iir.v
// Single biquad IIR (Direct Form Transposed) — processes 1 sample per cycle
// Q1.15 fixed point for inputs and coefficients.
// Interface: AXI-Stream like (s_tdata, s_tvalid, s_tready, m_tdata, m_tvalid, m_tready)
// Coefficients: b0,b1,b2 (feedforward), a1,a2 (feedback) in Q1.15 (signed 16-bit)
//
// Direct Form Transposed realization:
// y[n] = b0*x[n] + d1
// d1_next = b1*x[n] + a1*y[n] + d2
// d2_next = b2*x[n] + a2*y[n]
//

`timescale 1ns/1ps
module iir_biquad #(
  parameter integer DATA_WIDTH = 16,   // Q1.15
  parameter integer COEFF_WIDTH = 16,
  parameter integer ACC_WIDTH = 48
)(
  input  wire clk,
  input  wire rstn,

  // stream in/out
  input  wire signed [DATA_WIDTH-1:0] s_tdata,
  input  wire s_tvalid,
  output wire s_tready,

  output reg signed [DATA_WIDTH-1:0] m_tdata,
  output reg m_tvalid,
  input  wire m_tready,

  // coefficient write interface (synchronous)
  input  wire coeff_wr, // pulse
  input  wire [2:0] coeff_id, // 0:b0,1:b1,2:b2,3:a1,4:a2
  input  wire signed [COEFF_WIDTH-1:0] coeff_w
);

  // coefficient registers
  reg signed [COEFF_WIDTH-1:0] b0, b1, b2, a1, a2;
  always @(posedge clk) begin
    if (!rstn) begin
      b0 <= 0; b1 <= 0; b2 <= 0; a1 <= 0; a2 <= 0;
    end else if (coeff_wr) begin
      case (coeff_id)
        3'd0: b0 <= coeff_w;
        3'd1: b1 <= coeff_w;
        3'd2: b2 <= coeff_w;
        3'd3: a1 <= coeff_w;
        3'd4: a2 <= coeff_w;
      endcase
    end
  end

  // state registers d1,d2 in extended precision
  reg signed [ACC_WIDTH-1:0] d1, d2;

  // multipliers results
  wire signed [DATA_WIDTH+COEFF_WIDTH-1:0] m_b0 = s_tdata * b0;
  wire signed [DATA_WIDTH+COEFF_WIDTH-1:0] m_b1 = s_tdata * b1;
  wire signed [DATA_WIDTH+COEFF_WIDTH-1:0] m_b2 = s_tdata * b2;
  // y is produced later; feedback multiplies will use y extended

  // combine to produce y: y = b0*x + d1
  // Note: d1 and mult widths must be aligned; we shift by COEFF_WIDTH (Q scaling)
  localparam integer SHIFT = COEFF_WIDTH;
  wire signed [ACC_WIDTH-1:0] b0_x = {{(ACC_WIDTH-(DATA_WIDTH+COEFF_WIDTH)){m_b0[DATA_WIDTH+COEFF_WIDTH-1]}}, m_b0} >>> SHIFT;
  wire signed [ACC_WIDTH-1:0] y_ext = b0_x + d1; // extended precision

  // compute next d1, d2 using current y (fixed-point multiply of a1*y etc)
  // need to compute a1*y and a2*y; first make y in Q1.15
  wire signed [DATA_WIDTH-1:0] y_out = y_ext[DATA_WIDTH-1:0]; // truncate (saturation not handled here)
  wire signed [DATA_WIDTH+COEFF_WIDTH-1:0] y_mul_a1 = y_out * a1;
  wire signed [DATA_WIDTH+COEFF_WIDTH-1:0] y_mul_a2 = y_out * a2;

  wire signed [ACC_WIDTH-1:0] y_a1 = {{(ACC_WIDTH-(DATA_WIDTH+COEFF_WIDTH)){y_mul_a1[DATA_WIDTH+COEFF_WIDTH-1]}}, y_mul_a1} >>> SHIFT;
  wire signed [ACC_WIDTH-1:0] y_a2 = {{(ACC_WIDTH-(DATA_WIDTH+COEFF_WIDTH)){y_mul_a2[DATA_WIDTH+COEFF_WIDTH-1]}}, y_mul_a2} >>> SHIFT;

  // m_b1 and m_b2 aligned:
  wire signed [ACC_WIDTH-1:0] b1_x = {{(ACC_WIDTH-(DATA_WIDTH+COEFF_WIDTH)){m_b1[DATA_WIDTH+COEFF_WIDTH-1]}}, m_b1} >>> SHIFT;
  wire signed [ACC_WIDTH-1:0] b2_x = {{(ACC_WIDTH-(DATA_WIDTH+COEFF_WIDTH)){m_b2[DATA_WIDTH+COEFF_WIDTH-1]}}, m_b2} >>> SHIFT;

  // next states:
  wire signed [ACC_WIDTH-1:0] d1_next = b1_x + y_a1 + d2;
  wire signed [ACC_WIDTH-1:0] d2_next = b2_x + y_a2;

  // ready/valid simple
  assign s_tready = 1'b1;

  always @(posedge clk) begin
    if (!rstn) begin
      d1 <= 0; d2 <= 0;
      m_tvalid <= 1'b0;
      m_tdata <= 0;
    end else begin
      if (s_tvalid && s_tready) begin
        // update states and output y
        d1 <= d1_next;
        d2 <= d2_next;

        // reduce y_ext to output width (Q1.15) with truncation/saturation
        // simple truncation:
        m_tdata <= y_ext[DATA_WIDTH-1:0];
        m_tvalid <= 1'b1;
      end else if (m_tvalid && m_tready) begin
        m_tvalid <= 1'b0;
      end
    end
  end

endmodule
