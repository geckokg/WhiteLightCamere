`timescale 1ns/1ps

module tb_power_seq;
  logic clk = 1'b0;
  logic rst_n = 1'b0;
  logic start = 1'b0;
  logic v18;
  logic v33;
  logic vpix;
  logic clk_en;
  logic reset_n;
  logic done;
  logic [2:0] state;

  always #5 clk = ~clk;

  cam_power_seq #(
    .SYS_CLK_HZ(1_000_000),
    .POWER_STEP_US(3),
    .CLOCK_SETTLE_US(2),
    .POST_RESET_US(2)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .vdd_1v8_en(v18),
    .vdd_3v3_en(v33),
    .vdd_pix_en(vpix),
    .sensor_clk_en(clk_en),
    .sensor_reset_n(reset_n),
    .done(done),
    .state(state)
  );

  initial begin
    repeat (3) @(posedge clk);
    rst_n = 1'b1;
    start = 1'b1;

    wait (v18);
    wait (v33);
    if (!v18) $fatal(1, "3.3 V enabled before 1.8 V");
    wait (vpix);
    if (!v33) $fatal(1, "pixel rail enabled before 3.3 V");
    wait (clk_en);
    wait (reset_n);
    wait (done);
    $display("tb_power_seq PASS");
    $finish;
  end
endmodule
