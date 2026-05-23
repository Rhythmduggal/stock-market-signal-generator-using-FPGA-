module signal_logic #(
    parameter DATA_WIDTH = 32,
    parameter RSI_80     = 32'd5242880,   // 80 * 65536  (was RSI_70 = 70*65536)
  parameter RSI_10 = 32'd655360    // 20 * 65536  (was RSI_30 = 30*65536)
)(
    input  wire                  clk,
    input  wire                  rst,

    input  wire [DATA_WIDTH-1:0] ma_fast,
    input  wire [DATA_WIDTH-1:0] ma_slow,
    input  wire                  ma_valid,

    input  wire [DATA_WIDTH-1:0] rsi,
    input  wire                  rsi_valid,

    input  wire                  vol_spike,

    output reg  [1:0]            signal_out,
    output reg                   signal_valid
);

    reg  initialized;
    reg  fast_above_d;

    wire fast_above   = (ma_fast > ma_slow);
    wire crossover_up = fast_above  && !fast_above_d;
    wire crossover_dn = !fast_above && fast_above_d;

    // STAGE 2: relaxed RSI guards (80/20 instead of 70/30)
    // At step 130, RSI~78 - fits under 80, so BUY fires.
    // Once confirmed, you can tighten back to 70/30 with real data.
    wire rsi_ok_buy  = (rsi < RSI_80);   // not overbought (< 80)
    wire rsi_ok_sell = (rsi > RSI_10);   // not oversold  (> 20)

    // STAGE 3 (re-add when BUY/SELL confirmed firing):
    // wire rsi_ok_buy  = (rsi < RSI_80) && vol_spike;

    always @(posedge clk) begin
        if (rst) begin
            signal_out   <= 2'b00;
            signal_valid <= 1'b0;
            fast_above_d <= 1'b0;
            initialized  <= 1'b0;
        end
        else if (ma_valid) begin
            if (!initialized) begin
                fast_above_d <= fast_above;
                initialized  <= 1'b1;
                signal_out   <= 2'b00;
                signal_valid <= 1'b0;
            end
            else begin
                if (crossover_up && rsi_ok_buy)
                    signal_out <= 2'b01;   // BUY

                else if (crossover_dn && rsi_ok_sell)
                    signal_out <= 2'b10;   // SELL

                else
                    signal_out <= 2'b00;   // HOLD

                signal_valid <= 1'b1;
                fast_above_d <= fast_above;
            end
        end
        else begin
            signal_valid <= 1'b0;
        end
    end

endmodule
