module axi_frame_writer #(
  parameter int ADDR_WIDTH       = 32,
  parameter int DATA_WIDTH       = 64,
  parameter int IMG_WIDTH        = 1280,
  parameter int IMG_HEIGHT       = 1024,
  parameter int PIXELS_PER_BEAT  = 4,
  parameter int BURST_MAX_BEATS  = 16
) (
  input  logic clk,
  input  logic rst_n,
  input  logic enable,
  input  logic [ADDR_WIDTH-1:0] frame_base_addr,

  input  logic s_valid,
  output logic s_ready,
  input  logic s_sof,
  input  logic [DATA_WIDTH-1:0] s_data,

  output logic [ADDR_WIDTH-1:0] m_axi_awaddr,
  output logic [7:0] m_axi_awlen,
  output logic [2:0] m_axi_awsize,
  output logic [1:0] m_axi_awburst,
  output logic m_axi_awvalid,
  input  logic m_axi_awready,

  output logic [DATA_WIDTH-1:0] m_axi_wdata,
  output logic [DATA_WIDTH/8-1:0] m_axi_wstrb,
  output logic m_axi_wlast,
  output logic m_axi_wvalid,
  input  logic m_axi_wready,

  input  logic [1:0] m_axi_bresp,
  input  logic m_axi_bvalid,
  output logic m_axi_bready,

  output logic frame_done_pulse,
  output logic [31:0] frame_count,
  output logic [31:0] dropped_before_sof_count,
  output logic axi_error
);
  localparam int FRAME_BEATS = (IMG_WIDTH * IMG_HEIGHT) / PIXELS_PER_BEAT;
  localparam int BEAT_BYTES = DATA_WIDTH / 8;
  localparam int BEAT_LG_BYTES = $clog2(BEAT_BYTES);
  localparam int COUNT_W = $clog2(FRAME_BEATS + 1);
  localparam logic [ADDR_WIDTH-1:0] BEAT_BYTES_ADDR = BEAT_BYTES;
  localparam logic [COUNT_W-1:0] FRAME_BEATS_VALUE = FRAME_BEATS;
  localparam logic [7:0] BURST_MAX_VALUE = BURST_MAX_BEATS;

  localparam logic [2:0] S_WAIT_SOF = 3'd0;
  localparam logic [2:0] S_AW       = 3'd1;
  localparam logic [2:0] S_W        = 3'd2;
  localparam logic [2:0] S_B        = 3'd3;
  localparam logic [2:0] S_DONE     = 3'd4;

  logic [2:0] state;
  logic [COUNT_W-1:0] frame_beat_count;
  logic [7:0] burst_beats;
  logic [7:0] burst_sent;
  logic [ADDR_WIDTH-1:0] write_addr;

  function automatic logic [7:0] choose_burst(input logic [COUNT_W-1:0] remaining);
    if (remaining > BURST_MAX_BEATS) begin
      choose_burst = BURST_MAX_VALUE;
    end else begin
      choose_burst = remaining[7:0];
    end
  endfunction

  assign m_axi_awaddr  = write_addr;
  assign m_axi_awlen   = burst_beats - 1'b1;
  assign m_axi_awsize  = BEAT_LG_BYTES[2:0];
  assign m_axi_awburst = 2'b01;
  assign m_axi_awvalid = (state == S_AW);

  assign m_axi_wdata  = s_data;
  assign m_axi_wstrb  = {DATA_WIDTH/8{1'b1}};
  assign m_axi_wlast  = (burst_sent == (burst_beats - 1'b1));
  assign m_axi_wvalid = (state == S_W) && s_valid;
  assign s_ready      = ((state == S_WAIT_SOF) && s_valid && !s_sof) ||
                        ((state == S_W) && s_valid && m_axi_wready);
  assign m_axi_bready = (state == S_B);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state                    <= S_WAIT_SOF;
      frame_beat_count         <= '0;
      burst_beats              <= 8'd0;
      burst_sent               <= 8'd0;
      write_addr               <= '0;
      frame_done_pulse         <= 1'b0;
      frame_count              <= 32'd0;
      dropped_before_sof_count <= 32'd0;
      axi_error                <= 1'b0;
    end else begin
      frame_done_pulse <= 1'b0;

      if (!enable) begin
        state            <= S_WAIT_SOF;
        frame_beat_count <= '0;
        burst_beats      <= 8'd0;
        burst_sent       <= 8'd0;
        write_addr       <= frame_base_addr;
      end else begin
        unique case (state)
          S_WAIT_SOF: begin
            frame_beat_count <= '0;
            write_addr       <= frame_base_addr;
            if (s_valid && s_sof) begin
              burst_beats <= choose_burst(FRAME_BEATS_VALUE);
              burst_sent  <= 8'd0;
              state       <= S_AW;
            end else if (s_valid && !s_sof) begin
              dropped_before_sof_count <= dropped_before_sof_count + 1'b1;
            end
          end

          S_AW: begin
            if (m_axi_awready) begin
              state <= S_W;
            end
          end

          S_W: begin
            if (s_valid && m_axi_wready) begin
              frame_beat_count <= frame_beat_count + 1'b1;
              burst_sent       <= burst_sent + 1'b1;
              write_addr       <= write_addr + BEAT_BYTES_ADDR;
              if (m_axi_wlast) begin
                state <= S_B;
              end
            end
          end

          S_B: begin
            if (m_axi_bvalid) begin
              if (m_axi_bresp != 2'b00) begin
                axi_error <= 1'b1;
              end
              if (frame_beat_count == FRAME_BEATS_VALUE) begin
                state <= S_DONE;
              end else begin
                burst_beats <= choose_burst(FRAME_BEATS_VALUE - frame_beat_count);
                burst_sent  <= 8'd0;
                state       <= S_AW;
              end
            end
          end

          S_DONE: begin
            frame_done_pulse <= 1'b1;
            frame_count      <= frame_count + 1'b1;
            state            <= S_WAIT_SOF;
          end

          default: state <= S_WAIT_SOF;
        endcase
      end
    end
  end
endmodule
