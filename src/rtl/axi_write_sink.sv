module axi_write_sink #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 64
) (
  input  logic clk,
  input  logic rst_n,

  input  logic [ADDR_WIDTH-1:0] s_axi_awaddr,
  input  logic [7:0] s_axi_awlen,
  input  logic [2:0] s_axi_awsize,
  input  logic [1:0] s_axi_awburst,
  input  logic s_axi_awvalid,
  output logic s_axi_awready,

  input  logic [DATA_WIDTH-1:0] s_axi_wdata,
  input  logic [DATA_WIDTH/8-1:0] s_axi_wstrb,
  input  logic s_axi_wlast,
  input  logic s_axi_wvalid,
  output logic s_axi_wready,

  output logic [1:0] s_axi_bresp,
  output logic s_axi_bvalid,
  input  logic s_axi_bready,

  output logic [31:0] accepted_burst_count
);
  (* keep = "true" *) logic [31:0] sink_debug;

  assign s_axi_awready = 1'b1;
  assign s_axi_wready = 1'b1;
  assign s_axi_bresp = 2'b00;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s_axi_bvalid <= 1'b0;
      accepted_burst_count <= 32'd0;
      sink_debug <= 32'd0;
    end else begin
      if (s_axi_awvalid && s_axi_awready) begin
        sink_debug <= sink_debug ^ s_axi_awaddr ^
                      {16'd0, s_axi_awlen, 3'd0, s_axi_awsize, s_axi_awburst};
      end
      if (s_axi_wvalid && s_axi_wready && s_axi_wlast) begin
        s_axi_bvalid <= 1'b1;
        accepted_burst_count <= accepted_burst_count + 1'b1;
        sink_debug <= sink_debug ^ s_axi_wdata[31:0] ^ s_axi_wdata[63:32] ^
                      {24'd0, s_axi_wstrb};
      end else if (s_axi_bvalid && s_axi_bready) begin
        s_axi_bvalid <= 1'b0;
      end
    end
  end
endmodule
