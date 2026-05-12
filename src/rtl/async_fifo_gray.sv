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
  localparam int FIFO_DEPTH = 1 << ADDR_WIDTH;

  logic rst;
  logic wr_rst_busy;
  logic rd_rst_busy;

  assign rst = ~(wr_rst_n & rd_rst_n);

  xpm_fifo_async #(
    .CASCADE_HEIGHT(0),
    .CDC_SYNC_STAGES(2),
    .DOUT_RESET_VALUE("0"),
    .ECC_MODE("no_ecc"),
    .FIFO_MEMORY_TYPE("auto"),
    .FIFO_READ_LATENCY(0),
    .FIFO_WRITE_DEPTH(FIFO_DEPTH),
    .FULL_RESET_VALUE(0),
    .PROG_EMPTY_THRESH(10),
    .PROG_FULL_THRESH(FIFO_DEPTH - 10),
    .RD_DATA_COUNT_WIDTH(ADDR_WIDTH + 1),
    .READ_DATA_WIDTH(DATA_WIDTH),
    .READ_MODE("fwft"),
    .RELATED_CLOCKS(0),
    .SIM_ASSERT_CHK(0),
    .USE_ADV_FEATURES("0000"),
    .WAKEUP_TIME(0),
    .WRITE_DATA_WIDTH(DATA_WIDTH),
    .WR_DATA_COUNT_WIDTH(ADDR_WIDTH + 1)
  ) xpm_fifo_async_i (
    .almost_empty(),
    .almost_full(),
    .data_valid(),
    .dbiterr(),
    .dout(rd_data),
    .empty(empty),
    .full(full),
    .overflow(),
    .prog_empty(),
    .prog_full(),
    .rd_data_count(),
    .rd_rst_busy(rd_rst_busy),
    .sbiterr(),
    .underflow(),
    .wr_ack(),
    .wr_data_count(),
    .wr_rst_busy(wr_rst_busy),
    .din(wr_data),
    .injectdbiterr(1'b0),
    .injectsbiterr(1'b0),
    .rd_clk(rd_clk),
    .rd_en(rd_en),
    .rst(rst),
    .sleep(1'b0),
    .wr_clk(wr_clk),
    .wr_en(wr_en)
  );

  wire unused_busy = wr_rst_busy ^ rd_rst_busy;
endmodule
