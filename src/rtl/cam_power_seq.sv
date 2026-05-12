module cam_power_seq #(
  parameter int SYS_CLK_HZ        = 100_000_000,
  parameter int POWER_STEP_US     = 100,
  parameter int CLOCK_SETTLE_US   = 100,
  parameter int POST_RESET_US     = 100
) (
  input  logic clk,
  input  logic rst_n,
  input  logic start,

  output logic vdd_1v8_en,
  output logic vdd_3v3_en,
  output logic vdd_pix_en,
  output logic sensor_clk_en,
  output logic sensor_reset_n,
  output logic done,
  output logic [2:0] state
);
  localparam int CYCLES_PER_US = (SYS_CLK_HZ + 999_999) / 1_000_000;
  localparam int POWER_DELAY_CYCLES = POWER_STEP_US * CYCLES_PER_US;
  localparam int CLOCK_DELAY_CYCLES = CLOCK_SETTLE_US * CYCLES_PER_US;
  localparam int RESET_DELAY_CYCLES = POST_RESET_US * CYCLES_PER_US;
  localparam int TIMER_W = 32;
  localparam logic [TIMER_W-1:0] POWER_DELAY_VALUE = POWER_DELAY_CYCLES;
  localparam logic [TIMER_W-1:0] CLOCK_DELAY_VALUE = CLOCK_DELAY_CYCLES;
  localparam logic [TIMER_W-1:0] RESET_DELAY_VALUE = RESET_DELAY_CYCLES;

  localparam logic [2:0] S_IDLE       = 3'd0;
  localparam logic [2:0] S_1V8        = 3'd1;
  localparam logic [2:0] S_3V3        = 3'd2;
  localparam logic [2:0] S_PIX        = 3'd3;
  localparam logic [2:0] S_CLK_SETTLE = 3'd4;
  localparam logic [2:0] S_RESET_WAIT = 3'd5;
  localparam logic [2:0] S_DONE       = 3'd6;

  logic [TIMER_W-1:0] timer;

  function automatic logic timer_expired(input logic [TIMER_W-1:0] value);
    timer_expired = (value == 0);
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state          <= S_IDLE;
      timer          <= '0;
      vdd_1v8_en     <= 1'b0;
      vdd_3v3_en     <= 1'b0;
      vdd_pix_en     <= 1'b0;
      sensor_clk_en  <= 1'b0;
      sensor_reset_n <= 1'b0;
      done           <= 1'b0;
    end else begin
      done <= 1'b0;

      case (state)
        S_IDLE: begin
          vdd_1v8_en     <= 1'b0;
          vdd_3v3_en     <= 1'b0;
          vdd_pix_en     <= 1'b0;
          sensor_clk_en  <= 1'b0;
          sensor_reset_n <= 1'b0;
          if (start) begin
            vdd_1v8_en <= 1'b1;
            timer      <= POWER_DELAY_VALUE;
            state      <= S_1V8;
          end
        end

        S_1V8: begin
          if (timer_expired(timer)) begin
            vdd_3v3_en <= 1'b1;
            timer      <= POWER_DELAY_VALUE;
            state      <= S_3V3;
          end else begin
            timer <= timer - 1'b1;
          end
        end

        S_3V3: begin
          if (timer_expired(timer)) begin
            vdd_pix_en <= 1'b1;
            timer      <= POWER_DELAY_VALUE;
            state      <= S_PIX;
          end else begin
            timer <= timer - 1'b1;
          end
        end

        S_PIX: begin
          if (timer_expired(timer)) begin
            sensor_clk_en <= 1'b1;
            timer         <= CLOCK_DELAY_VALUE;
            state         <= S_CLK_SETTLE;
          end else begin
            timer <= timer - 1'b1;
          end
        end

        S_CLK_SETTLE: begin
          if (timer_expired(timer)) begin
            sensor_reset_n <= 1'b1;
            timer          <= RESET_DELAY_VALUE;
            state          <= S_RESET_WAIT;
          end else begin
            timer <= timer - 1'b1;
          end
        end

        S_RESET_WAIT: begin
          if (timer_expired(timer)) begin
            state <= S_DONE;
          end else begin
            timer <= timer - 1'b1;
          end
        end

        S_DONE: begin
          done <= 1'b1;
          if (!start) begin
            state <= S_IDLE;
          end
        end

        default: state <= S_IDLE;
      endcase
    end
  end
endmodule
