package python1300_pkg;
  localparam int PY1300_SPI_ADDR_W = 9;
  localparam int PY1300_SPI_DATA_W = 16;

  localparam int PY1300_ACTIVE_WIDTH  = 1280;
  localparam int PY1300_ACTIVE_HEIGHT = 1024;
  localparam int PY1300_PIXEL_BITS    = 10;
  localparam int PY1300_LVDS_LANES    = 4;
  localparam int PY1300_KERNEL_PIXELS = 8;

  localparam logic [15:0] PY1300_CHIP_ID = 16'h50D0;

  localparam logic [8:0] REG_CHIP_ID       = 9'd0;
  localparam logic [8:0] REG_PLL_POWER     = 9'd16;
  localparam logic [8:0] REG_IO_CONFIG1    = 9'd20;
  localparam logic [8:0] REG_PLL_LOCK      = 9'd24;
  localparam logic [8:0] REG_CGEN_CONFIG0  = 9'd32;
  localparam logic [8:0] REG_LOGIC_CONFIG0 = 9'd34;
  localparam logic [8:0] REG_IMG_CORE0     = 9'd40;
  localparam logic [8:0] REG_AFE_POWER     = 9'd48;
  localparam logic [8:0] REG_BIAS_POWER    = 9'd64;
  localparam logic [8:0] REG_CHARGE_PUMP   = 9'd72;
  localparam logic [8:0] REG_LVDS_POWER    = 9'd112;
  localparam logic [8:0] REG_TRAINING_DATA = 9'd116;
  localparam logic [8:0] REG_SYNC_CODE0    = 9'd117;
  localparam logic [8:0] REG_SYNC_BL_EVEN  = 9'd118;
  localparam logic [8:0] REG_SYNC_IMG_EVEN = 9'd119;
  localparam logic [8:0] REG_SYNC_CRC      = 9'd125;
  localparam logic [8:0] REG_SYNC_TR       = 9'd126;
  localparam logic [8:0] REG_DATA_CONFIG   = 9'd129;
  localparam logic [8:0] REG_SEQ_CONFIG    = 9'd192;
  localparam logic [8:0] REG_INT_CONTROL   = 9'd194;
  localparam logic [8:0] REG_ROI_ACTIVE    = 9'd195;
  localparam logic [8:0] REG_BLACK_LINES   = 9'd197;
  localparam logic [8:0] REG_MULT_TIMER    = 9'd199;
  localparam logic [8:0] REG_FRAME_LENGTH  = 9'd200;
  localparam logic [8:0] REG_EXPOSURE      = 9'd201;
  localparam logic [8:0] REG_GAIN          = 9'd204;
  localparam logic [8:0] REG_DIGITAL_GAIN  = 9'd205;
  localparam logic [8:0] REG_SYNC_CONFIG   = 9'd206;
  localparam logic [8:0] REG_ROI0_X        = 9'd256;
  localparam logic [8:0] REG_ROI0_Y_START  = 9'd257;
  localparam logic [8:0] REG_ROI0_Y_END    = 9'd258;

  localparam logic [9:0] SYNC_WORD_BL  = 10'h015;
  localparam logic [9:0] SYNC_WORD_IMG = 10'h035;
  localparam logic [9:0] SYNC_WORD_CRC = 10'h059;
  localparam logic [9:0] SYNC_WORD_TR  = 10'h3A6;

  localparam logic [6:0] FRAME_SYNC_LSB = 7'h2A;
  localparam logic [2:0] FRAME_CODE_LS  = 3'h1;
  localparam logic [2:0] FRAME_CODE_LE  = 3'h2;
  localparam logic [2:0] FRAME_CODE_FS  = 3'h5;
  localparam logic [2:0] FRAME_CODE_FE  = 3'h6;

  localparam logic [2:0] INIT_OP_END   = 3'd0;
  localparam logic [2:0] INIT_OP_WRITE = 3'd1;
  localparam logic [2:0] INIT_OP_DELAY = 3'd2;
  localparam logic [2:0] INIT_OP_POLL  = 3'd3;
endpackage
