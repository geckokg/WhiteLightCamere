module python1300_init_ctrl #(
  parameter int SYS_CLK_HZ      = 100_000_000,
  parameter int POLL_TIMEOUT_US = 100_000
) (
  input  logic clk,
  input  logic rst_n,
  input  logic start,

  output logic spi_start,
  output logic spi_write_not_read,
  output logic [8:0] spi_addr,
  output logic [15:0] spi_wdata,
  input  logic [15:0] spi_rdata,
  input  logic spi_busy,
  input  logic spi_done,

  output logic done,
  output logic chip_id_ok,
  output logic fault,
  output logic [7:0] fault_code,
  output logic [7:0] rom_index_dbg,
  output logic [15:0] last_read_dbg
);
  import python1300_pkg::*;

  localparam int CYCLES_PER_US = (SYS_CLK_HZ + 999_999) / 1_000_000;
  localparam int POLL_TIMEOUT_CYCLES = POLL_TIMEOUT_US * CYCLES_PER_US;
  localparam logic [31:0] POLL_TIMEOUT_VALUE = POLL_TIMEOUT_CYCLES;

  localparam logic [3:0] S_IDLE       = 4'd0;
  localparam logic [3:0] S_READ_ID    = 4'd1;
  localparam logic [3:0] S_WAIT_ID    = 4'd2;
  localparam logic [3:0] S_FETCH      = 4'd3;
  localparam logic [3:0] S_WRITE      = 4'd4;
  localparam logic [3:0] S_WAIT_WRITE = 4'd5;
  localparam logic [3:0] S_DELAY      = 4'd6;
  localparam logic [3:0] S_POLL       = 4'd7;
  localparam logic [3:0] S_WAIT_POLL  = 4'd8;
  localparam logic [3:0] S_DONE       = 4'd9;
  localparam logic [3:0] S_FAULT      = 4'd10;

  logic [3:0] state;
  logic [7:0] rom_index;
  logic [2:0] rom_op;
  logic [8:0] rom_addr;
  logic [15:0] rom_data;
  logic [15:0] rom_aux;
  logic [31:0] timer;
  logic [31:0] poll_timer;

  python1300_init_rom init_rom_i (
    .index(rom_index),
    .op(rom_op),
    .addr(rom_addr),
    .data(rom_data),
    .aux(rom_aux)
  );

  assign rom_index_dbg = rom_index;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state              <= S_IDLE;
      rom_index          <= 8'd0;
      timer              <= 32'd0;
      poll_timer         <= 32'd0;
      spi_start          <= 1'b0;
      spi_write_not_read <= 1'b0;
      spi_addr           <= '0;
      spi_wdata          <= '0;
      done               <= 1'b0;
      chip_id_ok         <= 1'b0;
      fault              <= 1'b0;
      fault_code         <= 8'd0;
      last_read_dbg      <= 16'd0;
    end else begin
      spi_start <= 1'b0;
      done      <= 1'b0;

      case (state)
        S_IDLE: begin
          rom_index  <= 8'd0;
          chip_id_ok <= 1'b0;
          fault      <= 1'b0;
          fault_code <= 8'd0;
          if (start) begin
            state <= S_READ_ID;
          end
        end

        S_READ_ID: begin
          if (!spi_busy) begin
            spi_start          <= 1'b1;
            spi_write_not_read <= 1'b0;
            spi_addr           <= REG_CHIP_ID;
            spi_wdata          <= 16'd0;
            state              <= S_WAIT_ID;
          end
        end

        S_WAIT_ID: begin
          if (spi_done) begin
            last_read_dbg <= spi_rdata;
            if (spi_rdata == PY1300_CHIP_ID) begin
              chip_id_ok <= 1'b1;
              state      <= S_FETCH;
            end else begin
              fault      <= 1'b1;
              fault_code <= 8'h01;
              state      <= S_FAULT;
            end
          end
        end

        S_FETCH: begin
          unique case (rom_op)
            INIT_OP_END: begin
              state <= S_DONE;
            end
            INIT_OP_WRITE: begin
              state <= S_WRITE;
            end
            INIT_OP_DELAY: begin
              timer <= rom_data * CYCLES_PER_US;
              state <= S_DELAY;
            end
            INIT_OP_POLL: begin
              poll_timer <= POLL_TIMEOUT_VALUE;
              state      <= S_POLL;
            end
            default: begin
              fault      <= 1'b1;
              fault_code <= 8'h02;
              state      <= S_FAULT;
            end
          endcase
        end

        S_WRITE: begin
          if (!spi_busy) begin
            spi_start          <= 1'b1;
            spi_write_not_read <= 1'b1;
            spi_addr           <= rom_addr;
            spi_wdata          <= rom_data;
            state              <= S_WAIT_WRITE;
          end
        end

        S_WAIT_WRITE: begin
          if (spi_done) begin
            rom_index <= rom_index + 1'b1;
            state     <= S_FETCH;
          end
        end

        S_DELAY: begin
          if (timer == 0) begin
            rom_index <= rom_index + 1'b1;
            state     <= S_FETCH;
          end else begin
            timer <= timer - 1'b1;
          end
        end

        S_POLL: begin
          if (!spi_busy) begin
            spi_start          <= 1'b1;
            spi_write_not_read <= 1'b0;
            spi_addr           <= rom_addr;
            spi_wdata          <= 16'd0;
            state              <= S_WAIT_POLL;
          end
        end

        S_WAIT_POLL: begin
          if (spi_done) begin
            last_read_dbg <= spi_rdata;
            if ((spi_rdata & rom_data) == rom_aux) begin
              rom_index <= rom_index + 1'b1;
              state     <= S_FETCH;
            end else if (poll_timer == 0) begin
              fault      <= 1'b1;
              fault_code <= 8'h03;
              state      <= S_FAULT;
            end else begin
              poll_timer <= poll_timer - 1'b1;
              state      <= S_POLL;
            end
          end
        end

        S_DONE: begin
          done <= 1'b1;
          if (!start) begin
            state <= S_IDLE;
          end
        end

        S_FAULT: begin
          fault <= 1'b1;
          if (!start) begin
            state <= S_IDLE;
          end
        end

        default: state <= S_IDLE;
      endcase
    end
  end
endmodule
