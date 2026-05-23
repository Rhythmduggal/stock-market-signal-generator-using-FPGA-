module ema #(
    parameter DATA_WIDTH  = 32,
    parameter ALPHA       = 8738,    // 2/(14+1) in Q0.16
    parameter ONE_M_ALPHA = 56798    // 1 - alpha in Q0.16
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  en,
    input  wire [DATA_WIDTH-1:0] price_in,
    output reg  [DATA_WIDTH-1:0] ema_out,
    output reg                   valid
);
 
    reg seeded;  // 1 after first sample received
 
    // EMA formula terms - use registered ema_out as prev value
    wire [63:0] term1 = ({32'd0, price_in} * ALPHA)    >> 16;
    wire [63:0] term2 = ({32'd0, ema_out}  * ONE_M_ALPHA) >> 16;
 
    always @(posedge clk) begin
        if (rst) begin
            ema_out <= 0;
            valid   <= 0;
            seeded  <= 0;
        end
        else if (en) begin
            if (!seeded) begin
                // First sample: seed EMA directly with price
                // This avoids the long cold-start from zero
                ema_out <= price_in;
                seeded  <= 1;
                valid   <= 0;  // not valid yet - need at least 2 samples
            end
            else begin
                // Normal EMA update from sample 2 onward
                ema_out <= term1[DATA_WIDTH-1:0] + term2[DATA_WIDTH-1:0];
                valid   <= 1;
            end
        end
        else begin
            valid <= 0;
        end
    end
 
endmodule
