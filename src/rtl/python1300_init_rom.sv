`timescale 1ns/1ps

module python1300_init_rom (
  input  logic [7:0] index,
  output logic [2:0] op,
  output logic [8:0] addr,
  output logic [15:0] data,
  output logic [15:0] aux
);
  import python1300_pkg::*;

  always_comb begin
    op   = INIT_OP_END;
    addr = 9'd0;
    data = 16'd0;
    aux  = 16'd0;

    unique case (index)
      // Enable the sensor input clock path, then start the PLL from the 72 MHz clk_pll pin.
      8'd0:  begin op = INIT_OP_WRITE; addr = REG_IO_CONFIG1;    data = 16'h0001; end
      8'd1:  begin op = INIT_OP_WRITE; addr = REG_PLL_POWER;     data = 16'h0003; end
      8'd2:  begin op = INIT_OP_DELAY;                            data = 16'd1000; end
      8'd3:  begin op = INIT_OP_POLL;  addr = REG_PLL_LOCK;      data = 16'h0001; aux = 16'h0001; end

      // Bring internal clocks and processing blocks out of power-down.
      8'd4:  begin op = INIT_OP_WRITE; addr = REG_CGEN_CONFIG0;  data = 16'h0007; end
      8'd5:  begin op = INIT_OP_WRITE; addr = REG_LOGIC_CONFIG0; data = 16'h0001; end
      8'd6:  begin op = INIT_OP_WRITE; addr = REG_BIAS_POWER;    data = 16'h0001; end
      8'd7:  begin op = INIT_OP_WRITE; addr = REG_CHARGE_PUMP;   data = 16'h2227; end
      8'd8:  begin op = INIT_OP_WRITE; addr = REG_IMG_CORE0;     data = 16'h0007; end
      8'd9:  begin op = INIT_OP_WRITE; addr = REG_AFE_POWER;     data = 16'h0001; end

      // LVDS output path and default 10-bit sync/training values.
      8'd10: begin op = INIT_OP_WRITE; addr = REG_LVDS_POWER;    data = 16'h0007; end
      8'd11: begin op = INIT_OP_WRITE; addr = REG_TRAINING_DATA; data = 16'h03A6; end
      8'd12: begin op = INIT_OP_WRITE; addr = REG_SYNC_CODE0;    data = 16'h002A; end
      8'd13: begin op = INIT_OP_WRITE; addr = REG_SYNC_BL_EVEN;  data = 16'h0015; end
      8'd14: begin op = INIT_OP_WRITE; addr = REG_SYNC_IMG_EVEN; data = 16'h0035; end
      8'd15: begin op = INIT_OP_WRITE; addr = REG_SYNC_CRC;      data = 16'h0059; end
      8'd16: begin op = INIT_OP_WRITE; addr = REG_SYNC_TR;       data = 16'h03A6; end
      8'd17: begin op = INIT_OP_WRITE; addr = REG_DATA_CONFIG;   data = 16'h0001; end

      // Full-frame ROI 0, 10-bit, normal ROT, continuous global-shutter master mode.
      8'd18: begin op = INIT_OP_WRITE; addr = REG_SEQ_CONFIG;    data = 16'h0000; end
      8'd19: begin op = INIT_OP_WRITE; addr = REG_INT_CONTROL;   data = 16'h00E4; end
      8'd20: begin op = INIT_OP_WRITE; addr = REG_ROI_ACTIVE;    data = 16'h0001; end
      8'd21: begin op = INIT_OP_WRITE; addr = REG_BLACK_LINES;   data = 16'h0102; end
      8'd22: begin op = INIT_OP_WRITE; addr = REG_MULT_TIMER;    data = 16'h0001; end
      8'd23: begin op = INIT_OP_WRITE; addr = REG_FRAME_LENGTH;  data = 16'h0600; end
      8'd24: begin op = INIT_OP_WRITE; addr = REG_EXPOSURE;      data = 16'h0200; end
      8'd25: begin op = INIT_OP_WRITE; addr = REG_GAIN;          data = 16'h01E3; end
      8'd26: begin op = INIT_OP_WRITE; addr = REG_DIGITAL_GAIN;  data = 16'h0080; end
      8'd27: begin op = INIT_OP_WRITE; addr = REG_SYNC_CONFIG;   data = 16'h037F; end
      8'd28: begin op = INIT_OP_WRITE; addr = REG_ROI0_X;        data = 16'h9F00; end
      8'd29: begin op = INIT_OP_WRITE; addr = REG_ROI0_Y_START;  data = 16'h0000; end
      8'd30: begin op = INIT_OP_WRITE; addr = REG_ROI0_Y_END;    data = 16'h03FF; end

      // Start grabbing frames. Keep this as the final write so bring-up can stop before it.
      8'd31: begin op = INIT_OP_DELAY;                            data = 16'd1000; end
      8'd32: begin op = INIT_OP_WRITE; addr = REG_SEQ_CONFIG;    data = 16'h0001; end
      default: begin op = INIT_OP_END; end
    endcase
  end
endmodule
