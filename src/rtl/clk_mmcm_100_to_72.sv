module clk_mmcm_100_to_72 (
  input  logic clk_100m_p,
  input  logic clk_100m_n,
  output logic clk_100m,
  output logic clk_72m,
  output logic locked
);
  logic clk_100m_ibuf;
  logic clkfb;
  logic clkfb_buf;
  logic clk_72m_raw;

  IBUFDS #(
    .DIFF_TERM("FALSE"),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("LVDS")
  ) sys_clk_ibufds_i (
    .I(clk_100m_p),
    .IB(clk_100m_n),
    .O(clk_100m_ibuf)
  );

  BUFG sys_clk_bufg_i (
    .I(clk_100m_ibuf),
    .O(clk_100m)
  );

  MMCME4_BASE #(
    .CLKIN1_PERIOD(10.000),
    .DIVCLK_DIVIDE(5),
    .CLKFBOUT_MULT_F(36.000),
    .CLKOUT0_DIVIDE_F(10.000),
    .CLKOUT0_DUTY_CYCLE(0.500),
    .CLKOUT0_PHASE(0.000),
    .CLKFBOUT_PHASE(0.000),
    .STARTUP_WAIT("FALSE")
  ) mmcm_i (
    .CLKIN1(clk_100m),
    .CLKFBIN(clkfb_buf),
    .RST(1'b0),
    .PWRDWN(1'b0),
    .CLKFBOUT(clkfb),
    .CLKFBOUTB(),
    .CLKOUT0(clk_72m_raw),
    .CLKOUT0B(),
    .CLKOUT1(),
    .CLKOUT1B(),
    .CLKOUT2(),
    .CLKOUT2B(),
    .CLKOUT3(),
    .CLKOUT3B(),
    .CLKOUT4(),
    .CLKOUT5(),
    .CLKOUT6(),
    .LOCKED(locked)
  );

  BUFG clkfb_bufg_i (
    .I(clkfb),
    .O(clkfb_buf)
  );

  BUFG clk72_bufg_i (
    .I(clk_72m_raw),
    .O(clk_72m)
  );
endmodule
