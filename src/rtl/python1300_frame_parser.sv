`timescale 1ns/1ps

module python1300_frame_parser (
  input  logic clk,
  input  logic rst_n,

  input  logic word_valid,
  input  logic [9:0] sync_word,
  input  logic [9:0] data_word0,
  input  logic [9:0] data_word1,
  input  logic [9:0] data_word2,
  input  logic [9:0] data_word3,

  output logic img_group_valid,
  output logic img_group_sof,
  output logic img_line_start,
  output logic img_line_end,
  output logic [9:0] img_word0,
  output logic [9:0] img_word1,
  output logic [9:0] img_word2,
  output logic [9:0] img_word3,

  output logic frame_start_pulse,
  output logic frame_end_pulse,
  output logic line_start_pulse,
  output logic line_end_pulse,
  output logic [15:0] crc_word_count,
  output logic [31:0] frame_sync_error_count
);
  import python1300_pkg::*;

  logic sof_pending;
  logic line_start_pending;

  wire is_frame_sync = (sync_word[6:0] == FRAME_SYNC_LSB);
  wire [2:0] frame_code = sync_word[9:7];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      img_group_valid        <= 1'b0;
      img_group_sof          <= 1'b0;
      img_line_start         <= 1'b0;
      img_line_end           <= 1'b0;
      img_word0              <= 10'd0;
      img_word1              <= 10'd0;
      img_word2              <= 10'd0;
      img_word3              <= 10'd0;
      frame_start_pulse      <= 1'b0;
      frame_end_pulse        <= 1'b0;
      line_start_pulse       <= 1'b0;
      line_end_pulse         <= 1'b0;
      crc_word_count         <= 16'd0;
      frame_sync_error_count <= 32'd0;
      sof_pending            <= 1'b0;
      line_start_pending     <= 1'b0;
    end else begin
      img_group_valid   <= 1'b0;
      img_group_sof     <= 1'b0;
      img_line_start    <= 1'b0;
      img_line_end      <= 1'b0;
      frame_start_pulse <= 1'b0;
      frame_end_pulse   <= 1'b0;
      line_start_pulse  <= 1'b0;
      line_end_pulse    <= 1'b0;

      if (word_valid) begin
        if (is_frame_sync) begin
          unique case (frame_code)
            FRAME_CODE_FS: begin
              frame_start_pulse <= 1'b1;
              sof_pending       <= 1'b1;
              line_start_pending <= 1'b0;
            end
            FRAME_CODE_FE: begin
              frame_end_pulse <= 1'b1;
            end
            FRAME_CODE_LS: begin
              line_start_pulse <= 1'b1;
              line_start_pending <= 1'b1;
            end
            FRAME_CODE_LE: begin
              line_end_pulse <= 1'b1;
              line_start_pending <= 1'b0;
            end
            default: begin
              frame_sync_error_count <= frame_sync_error_count + 1'b1;
            end
          endcase
        end

        if (sync_word == SYNC_WORD_CRC) begin
          crc_word_count <= crc_word_count + 1'b1;
        end

        if (sync_word == SYNC_WORD_IMG) begin
          img_group_valid <= 1'b1;
          img_group_sof   <= sof_pending;
          img_line_start  <= line_start_pending;
          img_word0       <= data_word0;
          img_word1       <= data_word1;
          img_word2       <= data_word2;
          img_word3       <= data_word3;
          sof_pending     <= 1'b0;
          line_start_pending <= 1'b0;
        end
      end
    end
  end
endmodule
