module python1300_spi_master #(
  parameter int SYS_CLK_HZ = 100_000_000,
  parameter int SPI_HZ     = 2_000_000
) (
  input  logic clk,
  input  logic rst_n,

  input  logic start,
  input  logic write_not_read,
  input  logic [8:0] addr,
  input  logic [15:0] wdata,
  output logic [15:0] rdata,
  output logic busy,
  output logic done,

  output logic sck,
  output logic mosi,
  input  logic miso,
  output logic ss_n
);
  localparam int HALF_DIV_CALC = SYS_CLK_HZ / (2 * SPI_HZ);
  localparam int HALF_DIV = (HALF_DIV_CALC < 2) ? 2 : HALF_DIV_CALC;
  localparam int DIV_W = $clog2(HALF_DIV + 1);
  localparam logic [DIV_W-1:0] HALF_DIV_VALUE = HALF_DIV;

  localparam logic [1:0] S_IDLE   = 2'd0;
  localparam logic [1:0] S_ASSERT = 2'd1;
  localparam logic [1:0] S_SHIFT  = 2'd2;
  localparam logic [1:0] S_FINISH = 2'd3;

  logic [1:0] state;
  logic [DIV_W-1:0] div_cnt;
  logic [4:0] bit_idx;
  logic [25:0] tx_shift;
  logic [15:0] rx_shift;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state    <= S_IDLE;
      div_cnt  <= '0;
      bit_idx  <= 5'd25;
      tx_shift <= '0;
      rx_shift <= '0;
      rdata    <= '0;
      busy     <= 1'b0;
      done     <= 1'b0;
      sck      <= 1'b0;
      mosi     <= 1'b0;
      ss_n     <= 1'b1;
    end else begin
      done <= 1'b0;

      case (state)
        S_IDLE: begin
          busy    <= 1'b0;
          sck     <= 1'b0;
          ss_n    <= 1'b1;
          div_cnt <= '0;
          bit_idx <= 5'd25;
          if (start) begin
            busy     <= 1'b1;
            ss_n     <= 1'b0;
            tx_shift <= {addr, write_not_read, wdata};
            rx_shift <= '0;
            mosi     <= addr[8];
            div_cnt  <= HALF_DIV_VALUE;
            state    <= S_ASSERT;
          end
        end

        S_ASSERT: begin
          if (div_cnt == 0) begin
            div_cnt <= HALF_DIV_VALUE;
            state   <= S_SHIFT;
          end else begin
            div_cnt <= div_cnt - 1'b1;
          end
        end

        S_SHIFT: begin
          if (div_cnt != 0) begin
            div_cnt <= div_cnt - 1'b1;
          end else begin
            div_cnt <= HALF_DIV_VALUE;
            sck <= ~sck;

            if (!sck) begin
              // Rising SCK edge: sensor samples MOSI.
            end else begin
              // Falling SCK edge: system samples MISO and advances MOSI.
              if (!write_not_read && bit_idx <= 5'd15) begin
                rx_shift <= {rx_shift[14:0], miso};
              end

              if (bit_idx == 0) begin
                sck   <= 1'b0;
                state <= S_FINISH;
              end else begin
                bit_idx <= bit_idx - 1'b1;
                mosi    <= tx_shift[bit_idx - 1'b1];
              end
            end
          end
        end

        S_FINISH: begin
          if (div_cnt != 0) begin
            div_cnt <= div_cnt - 1'b1;
          end else begin
            ss_n  <= 1'b1;
            rdata <= rx_shift;
            done  <= 1'b1;
            busy  <= 1'b0;
            state <= S_IDLE;
          end
        end

        default: state <= S_IDLE;
      endcase
    end
  end
endmodule
