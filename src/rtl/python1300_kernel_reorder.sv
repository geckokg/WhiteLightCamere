module python1300_kernel_reorder (
  input  logic clk,
  input  logic rst_n,

  input  logic in_valid,
  input  logic in_sof,
  input  logic in_line_start,
  input  logic [9:0] in_word0,
  input  logic [9:0] in_word1,
  input  logic [9:0] in_word2,
  input  logic [9:0] in_word3,

  output logic out_valid,
  output logic out_sof,
  output logic [63:0] out_pixels,
  output logic [31:0] pixel_group_count
);
  logic [9:0] c0_word0;
  logic [9:0] c0_word1;
  logic [9:0] c0_word2;
  logic [9:0] c0_word3;
  logic c0_sof;
  logic half_kernel;
  logic kernel_odd;
  logic pending_valid;
  logic pending_sof;
  logic [63:0] pending_pixels;

  function automatic logic [63:0] pack4(
    input logic [9:0] p0,
    input logic [9:0] p1,
    input logic [9:0] p2,
    input logic [9:0] p3
  );
    pack4 = {6'd0, p3, 6'd0, p2, 6'd0, p1, 6'd0, p0};
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      c0_word0          <= 10'd0;
      c0_word1          <= 10'd0;
      c0_word2          <= 10'd0;
      c0_word3          <= 10'd0;
      c0_sof            <= 1'b0;
      half_kernel       <= 1'b0;
      kernel_odd        <= 1'b0;
      pending_valid     <= 1'b0;
      pending_sof       <= 1'b0;
      pending_pixels    <= 64'd0;
      out_valid         <= 1'b0;
      out_sof           <= 1'b0;
      out_pixels        <= 64'd0;
      pixel_group_count <= 32'd0;
    end else begin
      out_valid <= 1'b0;
      out_sof   <= 1'b0;

      if (pending_valid) begin
        out_valid      <= 1'b1;
        out_sof        <= pending_sof;
        out_pixels     <= pending_pixels;
        pending_valid  <= 1'b0;
        pending_sof    <= 1'b0;
      end

      if (in_valid) begin
        if (in_sof || in_line_start) begin
          half_kernel <= 1'b0;
          kernel_odd  <= 1'b0;
        end

        if (!half_kernel) begin
          c0_word0    <= in_word0;
          c0_word1    <= in_word1;
          c0_word2    <= in_word2;
          c0_word3    <= in_word3;
          c0_sof      <= in_sof;
          half_kernel <= 1'b1;
        end else begin
          half_kernel <= 1'b0;
          kernel_odd  <= ~kernel_odd;
          pixel_group_count <= pixel_group_count + 2'd2;

          if (!kernel_odd) begin
            out_valid      <= 1'b1;
            out_sof        <= c0_sof | in_sof;
            out_pixels     <= pack4(c0_word0, c0_word1, c0_word2, c0_word3);
            pending_valid  <= 1'b1;
            pending_pixels <= pack4(in_word0, in_word1, in_word2, in_word3);
          end else begin
            out_valid      <= 1'b1;
            out_sof        <= c0_sof | in_sof;
            out_pixels     <= pack4(in_word3, in_word2, in_word1, in_word0);
            pending_valid  <= 1'b1;
            pending_pixels <= pack4(c0_word3, c0_word2, c0_word1, c0_word0);
          end
        end
      end
    end
  end
endmodule
