module async_fifo_gray #(
  parameter int DATA_WIDTH = 66,
  parameter int ADDR_WIDTH = 10
) (
  input  logic wr_clk,
  input  logic wr_rst_n,
  input  logic wr_en,
  input  logic [DATA_WIDTH-1:0] wr_data,
  output logic full,

  input  logic rd_clk,
  input  logic rd_rst_n,
  input  logic rd_en,
  output logic [DATA_WIDTH-1:0] rd_data,
  output logic empty
);
  localparam int DEPTH = 1 << ADDR_WIDTH;

  logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
  logic [ADDR_WIDTH:0] wr_bin;
  logic [ADDR_WIDTH:0] rd_bin;
  logic [ADDR_WIDTH:0] wr_gray;
  logic [ADDR_WIDTH:0] rd_gray;
  logic [ADDR_WIDTH:0] wr_gray_rdclk_1;
  logic [ADDR_WIDTH:0] wr_gray_rdclk_2;
  logic [ADDR_WIDTH:0] rd_gray_wrclk_1;
  logic [ADDR_WIDTH:0] rd_gray_wrclk_2;

  function automatic logic [ADDR_WIDTH:0] bin2gray(input logic [ADDR_WIDTH:0] bin);
    bin2gray = (bin >> 1) ^ bin;
  endfunction

  wire [ADDR_WIDTH:0] wr_bin_next  = wr_bin + ((wr_en && !full) ? 1'b1 : 1'b0);
  wire [ADDR_WIDTH:0] wr_gray_next = bin2gray(wr_bin_next);
  wire [ADDR_WIDTH:0] rd_bin_next  = rd_bin + ((rd_en && !empty) ? 1'b1 : 1'b0);
  wire [ADDR_WIDTH:0] rd_gray_next = bin2gray(rd_bin_next);

  assign full  = (wr_gray_next == {~rd_gray_wrclk_2[ADDR_WIDTH:ADDR_WIDTH-1], rd_gray_wrclk_2[ADDR_WIDTH-2:0]});
  assign empty = (rd_gray == wr_gray_rdclk_2);

  always_ff @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
      wr_bin          <= '0;
      wr_gray         <= '0;
      rd_gray_wrclk_1 <= '0;
      rd_gray_wrclk_2 <= '0;
    end else begin
      rd_gray_wrclk_1 <= rd_gray;
      rd_gray_wrclk_2 <= rd_gray_wrclk_1;
      if (wr_en && !full) begin
        mem[wr_bin[ADDR_WIDTH-1:0]] <= wr_data;
        wr_bin  <= wr_bin_next;
        wr_gray <= wr_gray_next;
      end
    end
  end

  always_ff @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
      rd_bin          <= '0;
      rd_gray         <= '0;
      wr_gray_rdclk_1 <= '0;
      wr_gray_rdclk_2 <= '0;
      rd_data         <= '0;
    end else begin
      wr_gray_rdclk_1 <= wr_gray;
      wr_gray_rdclk_2 <= wr_gray_rdclk_1;
      rd_data <= mem[rd_bin[ADDR_WIDTH-1:0]];
      if (rd_en && !empty) begin
        rd_bin  <= rd_bin_next;
        rd_gray <= rd_gray_next;
      end
    end
  end
endmodule
