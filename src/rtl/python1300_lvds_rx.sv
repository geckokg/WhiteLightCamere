`timescale 1ns/1ps

module python1300_lvds_rx #(
  parameter int WORD_BITS = 10
) (
  input  logic rst_n,

  input  logic lvds_clk_p,
  input  logic lvds_clk_n,
  input  logic [3:0] lvds_data_p,
  input  logic [3:0] lvds_data_n,
  input  logic lvds_sync_p,
  input  logic lvds_sync_n,

  output logic word_clk,
  output logic word_valid,
  output logic [WORD_BITS-1:0] sync_word,
  output logic [WORD_BITS-1:0] data_word0,
  output logic [WORD_BITS-1:0] data_word1,
  output logic [WORD_BITS-1:0] data_word2,
  output logic [WORD_BITS-1:0] data_word3,
  output logic training_seen,
  output logic align_locked
);
  // This module is a synthesizable pin-level scaffold and a useful simulation model.
  // For 720 Mbps/lane hardware operation, replace the internals with a Vivado
  // SelectIO Wizard/IDELAY implementation that outputs the same word interface.
  localparam logic [WORD_BITS-1:0] TRAINING = 10'h3A6;

  logic [WORD_BITS-1:0] sh_sync;
  logic [WORD_BITS-1:0] sh_d0;
  logic [WORD_BITS-1:0] sh_d1;
  logic [WORD_BITS-1:0] sh_d2;
  logic [WORD_BITS-1:0] sh_d3;
  logic [$clog2(WORD_BITS)-1:0] bit_count;
  logic [7:0] lock_count;
  logic lvds_clk_ibuf;
  logic lvds_clk;
  logic lvds_sync;
  logic [3:0] lvds_data;
  wire [WORD_BITS-1:0] next_sync = {sh_sync[WORD_BITS-2:0], lvds_sync};
  wire [WORD_BITS-1:0] next_d0   = {sh_d0[WORD_BITS-2:0], lvds_data[0]};
  wire [WORD_BITS-1:0] next_d1   = {sh_d1[WORD_BITS-2:0], lvds_data[1]};
  wire [WORD_BITS-1:0] next_d2   = {sh_d2[WORD_BITS-2:0], lvds_data[2]};
  wire [WORD_BITS-1:0] next_d3   = {sh_d3[WORD_BITS-2:0], lvds_data[3]};
  wire word_boundary = (bit_count == WORD_BITS-1) || (!align_locked && (next_sync == TRAINING));

  IBUFDS #(
    .DIFF_TERM("FALSE"),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("LVDS")
  ) lvds_clk_ibufds_i (
    .I(lvds_clk_p),
    .IB(lvds_clk_n),
    .O(lvds_clk_ibuf)
  );

  BUFG lvds_clk_bufg_i (
    .I(lvds_clk_ibuf),
    .O(lvds_clk)
  );

  IBUFDS #(
    .DIFF_TERM("FALSE"),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("LVDS")
  ) lvds_sync_ibufds_i (
    .I(lvds_sync_p),
    .IB(lvds_sync_n),
    .O(lvds_sync)
  );

  genvar lane;
  generate
    for (lane = 0; lane < 4; lane = lane + 1) begin : gen_data_ibufds
      IBUFDS #(
        .DIFF_TERM("FALSE"),
        .IBUF_LOW_PWR("TRUE"),
        .IOSTANDARD("LVDS")
      ) lvds_data_ibufds_i (
        .I(lvds_data_p[lane]),
        .IB(lvds_data_n[lane]),
        .O(lvds_data[lane])
      );
    end
  endgenerate

  assign word_clk = lvds_clk;

  always_ff @(posedge lvds_clk or negedge rst_n) begin
    if (!rst_n) begin
      sh_sync       <= '0;
      sh_d0         <= '0;
      sh_d1         <= '0;
      sh_d2         <= '0;
      sh_d3         <= '0;
      bit_count     <= '0;
      word_valid    <= 1'b0;
      sync_word     <= '0;
      data_word0    <= '0;
      data_word1    <= '0;
      data_word2    <= '0;
      data_word3    <= '0;
      training_seen <= 1'b0;
      align_locked  <= 1'b0;
      lock_count    <= 8'd0;
    end else begin
      word_valid <= 1'b0;
      sh_sync <= next_sync;
      sh_d0   <= next_d0;
      sh_d1   <= next_d1;
      sh_d2   <= next_d2;
      sh_d3   <= next_d3;

      if (word_boundary) begin
        bit_count  <= '0;
        word_valid <= 1'b1;
        sync_word  <= next_sync;
        data_word0 <= next_d0;
        data_word1 <= next_d1;
        data_word2 <= next_d2;
        data_word3 <= next_d3;

        if (next_sync == TRAINING) begin
          training_seen <= 1'b1;
          if (lock_count != 8'hFF) begin
            lock_count <= lock_count + 1'b1;
          end
          if (lock_count >= 8'd15) begin
            align_locked <= 1'b1;
          end
        end
      end else begin
        bit_count <= bit_count + 1'b1;
      end
    end
  end
endmodule
