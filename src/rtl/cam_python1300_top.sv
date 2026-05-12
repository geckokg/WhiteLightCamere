module cam_python1300_top #(
  parameter int SYS_CLK_HZ             = 100_000_000,
  parameter int SPI_HZ                 = 2_000_000,
  parameter bit USE_TRIGGER0_AS_SS_N   = 1'b1,
  parameter int FIFO_ADDR_WIDTH        = 12,
  parameter int AXI_ADDR_WIDTH         = 32,
  parameter int AXI_DATA_WIDTH         = 64,
  parameter logic [AXI_ADDR_WIDTH-1:0] FRAME_BASE_ADDR = 32'h1000_0000
) (
  input  logic sys_clk,
  input  logic sys_rst_n,
  input  logic cam_ref_clk_72m,
  input  logic enable,

  output logic cam1_mosi,
  input  logic cam1_miso,
  output logic cam1_sck,
  output logic cam1_ss_n,
  output logic cam1_reset_n,
  output logic cam1_clk_pll,
  output logic cam1_vdd_1v8_en,
  output logic cam1_vdd_3v3_en,
  output logic cam1_trigger0,
  output logic cam1_trigger1,
  output logic cam1_trigger2,
  input  logic cam1_monitor0,
  input  logic cam1_monitor1,

  input  logic cam1_lvds_clk_out_p,
  input  logic cam1_lvds_clk_out_n,
  input  logic [3:0] cam1_lvds_data_p,
  input  logic [3:0] cam1_lvds_data_n,
  input  logic cam1_lvds_sync_p,
  input  logic cam1_lvds_sync_n,
  output logic cam1_lvds_clk_in_p,
  output logic cam1_lvds_clk_in_n,

  output logic [AXI_ADDR_WIDTH-1:0] m_axi_awaddr,
  output logic [7:0] m_axi_awlen,
  output logic [2:0] m_axi_awsize,
  output logic [1:0] m_axi_awburst,
  output logic m_axi_awvalid,
  input  logic m_axi_awready,
  output logic [AXI_DATA_WIDTH-1:0] m_axi_wdata,
  output logic [AXI_DATA_WIDTH/8-1:0] m_axi_wstrb,
  output logic m_axi_wlast,
  output logic m_axi_wvalid,
  input  logic m_axi_wready,
  input  logic [1:0] m_axi_bresp,
  input  logic m_axi_bvalid,
  output logic m_axi_bready,

  output logic [31:0] status,
  output logic [31:0] frame_count,
  output logic [31:0] error_count
);
  import python1300_pkg::*;

  logic power_done;
  logic power_clk_en;
  logic power_vdd_pix_en;
  logic [2:0] power_state;

  logic spi_start;
  logic spi_write_not_read;
  logic [8:0] spi_addr;
  logic [15:0] spi_wdata;
  logic [15:0] spi_rdata;
  logic spi_busy;
  logic spi_done;
  logic spi_ss_n;

  logic init_done;
  logic chip_id_ok;
  logic init_fault;
  logic [7:0] init_fault_code;
  logic [7:0] init_rom_index;
  logic [15:0] init_last_read;

  logic rx_word_clk;
  logic rx_word_valid;
  logic [9:0] rx_sync_word;
  logic [9:0] rx_word0;
  logic [9:0] rx_word1;
  logic [9:0] rx_word2;
  logic [9:0] rx_word3;
  logic training_seen;
  logic align_locked;

  logic img_group_valid;
  logic img_group_sof;
  logic img_line_start;
  logic img_line_end;
  logic [9:0] img_word0;
  logic [9:0] img_word1;
  logic [9:0] img_word2;
  logic [9:0] img_word3;
  logic frame_start_pulse;
  logic frame_end_pulse;
  logic line_start_pulse;
  logic line_end_pulse;
  logic [15:0] crc_word_count;
  logic [31:0] frame_sync_error_count;

  logic pix_valid;
  logic pix_sof;
  logic [63:0] pix_data;
  logic [31:0] pixel_group_count;

  logic fifo_full;
  logic fifo_empty;
  logic fifo_wr_en;
  logic fifo_rd_en;
  logic [64:0] fifo_wr_data;
  logic [64:0] fifo_rd_data;
  logic fifo_overflow;
  logic writer_ready;
  logic frame_done_pulse;
  logic [31:0] dropped_before_sof_count;
  logic axi_error;
  logic training_seen_sys1;
  logic training_seen_sys2;
  logic align_locked_sys1;
  logic align_locked_sys2;
  logic fifo_overflow_sys1;
  logic fifo_overflow_sys2;
  logic fifo_full_sys1;
  logic fifo_full_sys2;
  logic [31:0] frame_sync_error_count_sys1;
  logic [31:0] frame_sync_error_count_sys2;

  assign cam1_clk_pll = power_clk_en ? cam_ref_clk_72m : 1'b0;
  assign cam1_ss_n    = spi_ss_n;
  assign cam1_trigger0 = USE_TRIGGER0_AS_SS_N ? spi_ss_n : 1'b0;
  assign cam1_trigger1 = 1'b0;
  assign cam1_trigger2 = 1'b0;

  assign cam1_lvds_clk_in_p = 1'b0;
  assign cam1_lvds_clk_in_n = 1'b1;

  cam_power_seq #(
    .SYS_CLK_HZ(SYS_CLK_HZ),
    .POWER_STEP_US(100),
    .CLOCK_SETTLE_US(100),
    .POST_RESET_US(100)
  ) power_seq_i (
    .clk(sys_clk),
    .rst_n(sys_rst_n),
    .start(enable),
    .vdd_1v8_en(cam1_vdd_1v8_en),
    .vdd_3v3_en(cam1_vdd_3v3_en),
    .vdd_pix_en(power_vdd_pix_en),
    .sensor_clk_en(power_clk_en),
    .sensor_reset_n(cam1_reset_n),
    .done(power_done),
    .state(power_state)
  );

  python1300_spi_master #(
    .SYS_CLK_HZ(SYS_CLK_HZ),
    .SPI_HZ(SPI_HZ)
  ) spi_master_i (
    .clk(sys_clk),
    .rst_n(sys_rst_n),
    .start(spi_start),
    .write_not_read(spi_write_not_read),
    .addr(spi_addr),
    .wdata(spi_wdata),
    .rdata(spi_rdata),
    .busy(spi_busy),
    .done(spi_done),
    .sck(cam1_sck),
    .mosi(cam1_mosi),
    .miso(cam1_miso),
    .ss_n(spi_ss_n)
  );

  python1300_init_ctrl #(
    .SYS_CLK_HZ(SYS_CLK_HZ)
  ) init_ctrl_i (
    .clk(sys_clk),
    .rst_n(sys_rst_n),
    .start(power_done && enable),
    .spi_start(spi_start),
    .spi_write_not_read(spi_write_not_read),
    .spi_addr(spi_addr),
    .spi_wdata(spi_wdata),
    .spi_rdata(spi_rdata),
    .spi_busy(spi_busy),
    .spi_done(spi_done),
    .done(init_done),
    .chip_id_ok(chip_id_ok),
    .fault(init_fault),
    .fault_code(init_fault_code),
    .rom_index_dbg(init_rom_index),
    .last_read_dbg(init_last_read)
  );

  python1300_lvds_rx lvds_rx_i (
    .rst_n(sys_rst_n && init_done),
    .lvds_clk_p(cam1_lvds_clk_out_p),
    .lvds_clk_n(cam1_lvds_clk_out_n),
    .lvds_data_p(cam1_lvds_data_p),
    .lvds_data_n(cam1_lvds_data_n),
    .lvds_sync_p(cam1_lvds_sync_p),
    .lvds_sync_n(cam1_lvds_sync_n),
    .word_clk(rx_word_clk),
    .word_valid(rx_word_valid),
    .sync_word(rx_sync_word),
    .data_word0(rx_word0),
    .data_word1(rx_word1),
    .data_word2(rx_word2),
    .data_word3(rx_word3),
    .training_seen(training_seen),
    .align_locked(align_locked)
  );

  python1300_frame_parser frame_parser_i (
    .clk(rx_word_clk),
    .rst_n(sys_rst_n && init_done),
    .word_valid(rx_word_valid),
    .sync_word(rx_sync_word),
    .data_word0(rx_word0),
    .data_word1(rx_word1),
    .data_word2(rx_word2),
    .data_word3(rx_word3),
    .img_group_valid(img_group_valid),
    .img_group_sof(img_group_sof),
    .img_line_start(img_line_start),
    .img_line_end(img_line_end),
    .img_word0(img_word0),
    .img_word1(img_word1),
    .img_word2(img_word2),
    .img_word3(img_word3),
    .frame_start_pulse(frame_start_pulse),
    .frame_end_pulse(frame_end_pulse),
    .line_start_pulse(line_start_pulse),
    .line_end_pulse(line_end_pulse),
    .crc_word_count(crc_word_count),
    .frame_sync_error_count(frame_sync_error_count)
  );

  python1300_kernel_reorder kernel_reorder_i (
    .clk(rx_word_clk),
    .rst_n(sys_rst_n && init_done),
    .in_valid(img_group_valid),
    .in_sof(img_group_sof),
    .in_line_start(img_line_start),
    .in_word0(img_word0),
    .in_word1(img_word1),
    .in_word2(img_word2),
    .in_word3(img_word3),
    .out_valid(pix_valid),
    .out_sof(pix_sof),
    .out_pixels(pix_data),
    .pixel_group_count(pixel_group_count)
  );

  assign fifo_wr_en   = pix_valid && !fifo_full;
  assign fifo_wr_data = {pix_sof, pix_data};

  always_ff @(posedge rx_word_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
      fifo_overflow <= 1'b0;
    end else if (pix_valid && fifo_full) begin
      fifo_overflow <= 1'b1;
    end
  end

  async_fifo_gray #(
    .DATA_WIDTH(65),
    .ADDR_WIDTH(FIFO_ADDR_WIDTH)
  ) pixel_fifo_i (
    .wr_clk(rx_word_clk),
    .wr_rst_n(sys_rst_n && init_done),
    .wr_en(fifo_wr_en),
    .wr_data(fifo_wr_data),
    .full(fifo_full),
    .rd_clk(sys_clk),
    .rd_rst_n(sys_rst_n),
    .rd_en(fifo_rd_en),
    .rd_data(fifo_rd_data),
    .empty(fifo_empty)
  );

  assign fifo_rd_en = writer_ready && !fifo_empty;

  always_ff @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
      training_seen_sys1 <= 1'b0;
      training_seen_sys2 <= 1'b0;
      align_locked_sys1 <= 1'b0;
      align_locked_sys2 <= 1'b0;
      fifo_overflow_sys1 <= 1'b0;
      fifo_overflow_sys2 <= 1'b0;
      fifo_full_sys1 <= 1'b0;
      fifo_full_sys2 <= 1'b0;
      frame_sync_error_count_sys1 <= 32'd0;
      frame_sync_error_count_sys2 <= 32'd0;
    end else begin
      training_seen_sys1 <= training_seen;
      training_seen_sys2 <= training_seen_sys1;
      align_locked_sys1 <= align_locked;
      align_locked_sys2 <= align_locked_sys1;
      fifo_overflow_sys1 <= fifo_overflow;
      fifo_overflow_sys2 <= fifo_overflow_sys1;
      fifo_full_sys1 <= fifo_full;
      fifo_full_sys2 <= fifo_full_sys1;
      frame_sync_error_count_sys1 <= frame_sync_error_count;
      frame_sync_error_count_sys2 <= frame_sync_error_count_sys1;
    end
  end

  axi_frame_writer #(
    .ADDR_WIDTH(AXI_ADDR_WIDTH),
    .DATA_WIDTH(AXI_DATA_WIDTH),
    .IMG_WIDTH(PY1300_ACTIVE_WIDTH),
    .IMG_HEIGHT(PY1300_ACTIVE_HEIGHT),
    .PIXELS_PER_BEAT(4),
    .BURST_MAX_BEATS(16)
  ) frame_writer_i (
    .clk(sys_clk),
    .rst_n(sys_rst_n),
    .enable(init_done && enable && align_locked_sys2),
    .frame_base_addr(FRAME_BASE_ADDR),
    .s_valid(!fifo_empty),
    .s_ready(writer_ready),
    .s_sof(fifo_rd_data[64]),
    .s_data(fifo_rd_data[63:0]),
    .m_axi_awaddr(m_axi_awaddr),
    .m_axi_awlen(m_axi_awlen),
    .m_axi_awsize(m_axi_awsize),
    .m_axi_awburst(m_axi_awburst),
    .m_axi_awvalid(m_axi_awvalid),
    .m_axi_awready(m_axi_awready),
    .m_axi_wdata(m_axi_wdata),
    .m_axi_wstrb(m_axi_wstrb),
    .m_axi_wlast(m_axi_wlast),
    .m_axi_wvalid(m_axi_wvalid),
    .m_axi_wready(m_axi_wready),
    .m_axi_bresp(m_axi_bresp),
    .m_axi_bvalid(m_axi_bvalid),
    .m_axi_bready(m_axi_bready),
    .frame_done_pulse(frame_done_pulse),
    .frame_count(frame_count),
    .dropped_before_sof_count(dropped_before_sof_count),
    .axi_error(axi_error)
  );

  assign error_count = frame_sync_error_count_sys2 + dropped_before_sof_count +
                       {31'd0, fifo_overflow_sys2} + {31'd0, init_fault} + {31'd0, axi_error};

  assign status = {
    2'd0,
    cam1_monitor1,
    cam1_monitor0,
    power_vdd_pix_en,
    fifo_full_sys2,
    fifo_empty,
    init_fault_code,
    init_rom_index,
    axi_error,
    fifo_overflow_sys2,
    frame_done_pulse,
    align_locked_sys2,
    training_seen_sys2,
    init_fault,
    chip_id_ok,
    init_done,
    power_done
  };

  // Fail early during elaboration if someone changes AXI width without adding a packer.
  initial begin
    if (AXI_DATA_WIDTH != 64) begin
      $error("cam_python1300_top currently expects AXI_DATA_WIDTH=64.");
    end
  end
endmodule
