`timescale 1ns/1ps

module sei_pin_cam_a_top (
  input  logic sys_clk_p,
  input  logic sys_clk_n,

  input  logic i_lvds_clk_p,
  input  logic i_lvds_clk_n,
  input  logic i_lvds_sync_p,
  input  logic i_lvds_sync_n,
  input  logic i_lvds_data0_p,
  input  logic i_lvds_data0_n,
  input  logic i_lvds_data1_p,
  input  logic i_lvds_data1_n,
  input  logic i_lvds_data2_p,
  input  logic i_lvds_data2_n,
  input  logic i_lvds_data3_p,
  input  logic i_lvds_data3_n,

  output logic spi_sck,
  output logic spi_ss_n,
  output logic spi_mosi,
  input  logic spi_miso,

  output logic camera_reset_n,
  output logic camera_vdd_18_en,
  output logic camera_vdd_33_en,
  output logic camera_lvds_clk,
  output logic trigger_0
);
  logic sys_clk;
  logic clk_72m;
  logic clk_locked;
  logic [15:0] reset_pipe;
  logic sys_rst_n;

  logic [31:0] m_axi_awaddr;
  logic [7:0] m_axi_awlen;
  logic [2:0] m_axi_awsize;
  logic [1:0] m_axi_awburst;
  logic m_axi_awvalid;
  logic m_axi_awready;
  logic [63:0] m_axi_wdata;
  logic [7:0] m_axi_wstrb;
  logic m_axi_wlast;
  logic m_axi_wvalid;
  logic m_axi_wready;
  logic [1:0] m_axi_bresp;
  logic m_axi_bvalid;
  logic m_axi_bready;
  logic [31:0] status;
  logic [31:0] frame_count;
  logic [31:0] error_count;
  logic [31:0] accepted_burst_count;

  clk_mmcm_100_to_72 clkgen_i (
    .clk_100m_p(sys_clk_p),
    .clk_100m_n(sys_clk_n),
    .clk_100m(sys_clk),
    .clk_72m(clk_72m),
    .locked(clk_locked)
  );

  always_ff @(posedge sys_clk or negedge clk_locked) begin
    if (!clk_locked) begin
      reset_pipe <= 16'd0;
    end else begin
      reset_pipe <= {reset_pipe[14:0], 1'b1};
    end
  end

  assign sys_rst_n = reset_pipe[15];

  cam_python1300_top #(
    .SYS_CLK_HZ(100_000_000),
    .SPI_HZ(2_000_000),
    .USE_TRIGGER0_AS_SS_N(1'b0),
    .FRAME_BASE_ADDR(32'h1000_0000)
  ) cam_i (
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .cam_ref_clk_72m(clk_72m),
    .enable(1'b1),
    .cam1_mosi(spi_mosi),
    .cam1_miso(spi_miso),
    .cam1_sck(spi_sck),
    .cam1_ss_n(spi_ss_n),
    .cam1_reset_n(camera_reset_n),
    .cam1_clk_pll(camera_lvds_clk),
    .cam1_vdd_1v8_en(camera_vdd_18_en),
    .cam1_vdd_3v3_en(camera_vdd_33_en),
    .cam1_trigger0(trigger_0),
    .cam1_trigger1(),
    .cam1_trigger2(),
    .cam1_monitor0(1'b0),
    .cam1_monitor1(1'b0),
    .cam1_lvds_clk_out_p(i_lvds_clk_p),
    .cam1_lvds_clk_out_n(i_lvds_clk_n),
    .cam1_lvds_data_p({i_lvds_data3_p, i_lvds_data2_p, i_lvds_data1_p, i_lvds_data0_p}),
    .cam1_lvds_data_n({i_lvds_data3_n, i_lvds_data2_n, i_lvds_data1_n, i_lvds_data0_n}),
    .cam1_lvds_sync_p(i_lvds_sync_p),
    .cam1_lvds_sync_n(i_lvds_sync_n),
    .cam1_lvds_clk_in_p(),
    .cam1_lvds_clk_in_n(),
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
    .status(status),
    .frame_count(frame_count),
    .error_count(error_count)
  );

  axi_write_sink #(
    .ADDR_WIDTH(32),
    .DATA_WIDTH(64)
  ) axi_sink_i (
    .clk(sys_clk),
    .rst_n(sys_rst_n),
    .s_axi_awaddr(m_axi_awaddr),
    .s_axi_awlen(m_axi_awlen),
    .s_axi_awsize(m_axi_awsize),
    .s_axi_awburst(m_axi_awburst),
    .s_axi_awvalid(m_axi_awvalid),
    .s_axi_awready(m_axi_awready),
    .s_axi_wdata(m_axi_wdata),
    .s_axi_wstrb(m_axi_wstrb),
    .s_axi_wlast(m_axi_wlast),
    .s_axi_wvalid(m_axi_wvalid),
    .s_axi_wready(m_axi_wready),
    .s_axi_bresp(m_axi_bresp),
    .s_axi_bvalid(m_axi_bvalid),
    .s_axi_bready(m_axi_bready),
    .accepted_burst_count(accepted_burst_count)
  );

  wire unused_debug = ^status ^ ^frame_count ^ ^error_count ^ ^accepted_burst_count;
endmodule
