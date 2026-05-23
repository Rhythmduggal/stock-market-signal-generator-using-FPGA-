module rsi_calc #(
    parameter DATA_WIDTH = 32,
    parameter PERIOD     = 14,
    parameter SMOOTH_OLD = 60855,   // 13/14 in Q0.16
    parameter SMOOTH_NEW = 4681     // 1/14  in Q0.16
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  en,
    input  wire [DATA_WIDTH-1:0] price_in,
    output reg  [DATA_WIDTH-1:0] rsi_out,
    output reg                   valid
);
 
    reg [DATA_WIDTH-1:0] prev_price;
    reg [DATA_WIDTH-1:0] avg_gain;
    reg [DATA_WIDTH-1:0] avg_loss;
    reg                  initialized;
 
    // ---- Delta: signed comparison ----
    wire signed [DATA_WIDTH:0] delta =
        $signed({1'b0, price_in}) - $signed({1'b0, prev_price});
 
    wire [DATA_WIDTH-1:0] gain = (delta > 0) ? delta[DATA_WIDTH-1:0] : {DATA_WIDTH{1'b0}};
    wire [DATA_WIDTH-1:0] loss = (delta < 0) ? (-delta[DATA_WIDTH-1:0]) : {DATA_WIDTH{1'b0}};
 
    // ---- Wilder smoothing ----
    wire [63:0] gain_prod = (avg_gain * SMOOTH_OLD) + (gain * SMOOTH_NEW);
    wire [63:0] loss_prod = (avg_loss * SMOOTH_OLD) + (loss * SMOOTH_NEW);
 
    // Correct extraction: >>16 of 64-bit product = bits [47:16]
    wire [DATA_WIDTH-1:0] new_avg_gain = gain_prod[47:16];
    wire [DATA_WIDTH-1:0] new_avg_loss = loss_prod[47:16];
 
    // ---- RSI = 100 * avg_gain / (avg_gain + avg_loss) in Q16.16 ----
    wire [63:0] num   = (64'd100 * {32'd0, new_avg_gain}) << 16;
    wire [63:0] denom = {32'd0, new_avg_gain} + {32'd0, new_avg_loss};
 
    wire [63:0] rsi_64 = (denom == 64'd0) ? (64'd50 << 16) : (num / denom);
 
    // Clamp to 100 in Q16.16 = 6,553,600
    wire [DATA_WIDTH-1:0] rsi_raw =
        (rsi_64 > 64'd6553600) ? 32'd6553600 : rsi_64[DATA_WIDTH-1:0];
 
    always @(posedge clk) begin
        if (rst) begin
            prev_price  <= 0;
            avg_gain    <= 0;
            avg_loss    <= 0;
            initialized <= 0;
            rsi_out     <= 32'd50 << 16;
            valid       <= 0;
        end
        else if (en) begin
            if (!initialized) begin
                prev_price  <= price_in;
                initialized <= 1;
                valid       <= 0;
            end
            else begin
                avg_gain   <= new_avg_gain;
                avg_loss   <= new_avg_loss;
                prev_price <= price_in;
                rsi_out    <= rsi_raw;
                valid      <= 1;
            end
        end
        else begin
            valid <= 0;
        end
    end
 
endmodule
