`timescale 1ns/1ps

module tb_frame_path;
  import python1300_pkg::*;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  always #5 clk = ~clk;

  logic word_valid;
  logic [9:0] sync_word;
  logic [9:0] d0;
  logic [9:0] d1;
  logic [9:0] d2;
  logic [9:0] d3;

  logic img_valid;
  logic img_sof;
  logic img_line_start;
  logic img_line_end;
  logic [9:0] iw0;
  logic [9:0] iw1;
  logic [9:0] iw2;
  logic [9:0] iw3;
  logic fs;
  logic fe;
  logic ls;
  logic le;
  logic [15:0] crc_count;
  logic [31:0] sync_errors;

  logic pix_valid;
  logic pix_sof;
  logic [63:0] pix_data;
  logic [31:0] pixel_group_count;

  python1300_frame_parser parser_i (
    .clk(clk),
    .rst_n(rst_n),
    .word_valid(word_valid),
    .sync_word(sync_word),
    .data_word0(d0),
    .data_word1(d1),
    .data_word2(d2),
    .data_word3(d3),
    .img_group_valid(img_valid),
    .img_group_sof(img_sof),
    .img_line_start(img_line_start),
    .img_line_end(img_line_end),
    .img_word0(iw0),
    .img_word1(iw1),
    .img_word2(iw2),
    .img_word3(iw3),
    .frame_start_pulse(fs),
    .frame_end_pulse(fe),
    .line_start_pulse(ls),
    .line_end_pulse(le),
    .crc_word_count(crc_count),
    .frame_sync_error_count(sync_errors)
  );

  python1300_kernel_reorder reorder_i (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(img_valid),
    .in_sof(img_sof),
    .in_line_start(img_line_start),
    .in_word0(iw0),
    .in_word1(iw1),
    .in_word2(iw2),
    .in_word3(iw3),
    .out_valid(pix_valid),
    .out_sof(pix_sof),
    .out_pixels(pix_data),
    .pixel_group_count(pixel_group_count)
  );

  task automatic send_word(input logic [9:0] sw, input logic [9:0] a, b, c, d);
    begin
      @(posedge clk);
      word_valid <= 1'b1;
      sync_word  <= sw;
      d0 <= a;
      d1 <= b;
      d2 <= c;
      d3 <= d;
      @(posedge clk);
      word_valid <= 1'b0;
      sync_word  <= 10'd0;
      d0 <= 10'd0;
      d1 <= 10'd0;
      d2 <= 10'd0;
      d3 <= 10'd0;
    end
  endtask

  function automatic logic [63:0] pack4(
    input logic [9:0] p0,
    input logic [9:0] p1,
    input logic [9:0] p2,
    input logic [9:0] p3
  );
    pack4 = {6'd0, p3, 6'd0, p2, 6'd0, p1, 6'd0, p0};
  endfunction

  task automatic expect_beat(input logic expected_sof, input logic [63:0] expected_data);
    int wait_count;
    begin
      wait_count = 0;
      while (!pix_valid && wait_count < 16) begin
        @(posedge clk);
        wait_count++;
      end
      if (!pix_valid) begin
        $fatal(1, "expected pix_valid");
      end
      if (pix_sof !== expected_sof) begin
        $fatal(1, "SOF mismatch: got %0b expected %0b", pix_sof, expected_sof);
      end
      if (pix_data !== expected_data) begin
        $fatal(1, "pixel data mismatch: got %h expected %h", pix_data, expected_data);
      end
      @(posedge clk);
    end
  endtask

  initial begin
    word_valid = 1'b0;
    sync_word = 10'd0;
    d0 = 10'd0;
    d1 = 10'd0;
    d2 = 10'd0;
    d3 = 10'd0;

    repeat (5) @(posedge clk);
    rst_n = 1'b1;
    repeat (2) @(posedge clk);

    send_word({FRAME_CODE_FS, FRAME_SYNC_LSB}, 10'd0, 10'd0, 10'd0, 10'd0);
    send_word({FRAME_CODE_LS, FRAME_SYNC_LSB}, 10'd0, 10'd0, 10'd0, 10'd0);
    send_word(SYNC_WORD_IMG, 10'd0, 10'd1, 10'd2, 10'd3);
    send_word(SYNC_WORD_IMG, 10'd4, 10'd5, 10'd6, 10'd7);
    expect_beat(1'b1, pack4(0, 1, 2, 3));
    expect_beat(1'b0, pack4(4, 5, 6, 7));

    send_word(SYNC_WORD_IMG, 10'd15, 10'd14, 10'd13, 10'd12);
    send_word(SYNC_WORD_IMG, 10'd11, 10'd10, 10'd9, 10'd8);
    expect_beat(1'b0, pack4(8, 9, 10, 11));
    expect_beat(1'b0, pack4(12, 13, 14, 15));

    send_word({FRAME_CODE_LE, FRAME_SYNC_LSB}, 10'd0, 10'd0, 10'd0, 10'd0);
    send_word({FRAME_CODE_FE, FRAME_SYNC_LSB}, 10'd0, 10'd0, 10'd0, 10'd0);

    if (sync_errors != 0) begin
      $fatal(1, "unexpected sync errors: %0d", sync_errors);
    end

    $display("tb_frame_path PASS");
    $finish;
  end
endmodule
