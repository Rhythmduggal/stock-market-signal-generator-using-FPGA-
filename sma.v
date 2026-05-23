module sma #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH      = 14,
    // Reciprocal of DEPTH in Q16.16 format
    // For DEPTH=14: round(65536/14) = 4681
    // For DEPTH=50: round(65536/50) = 1311
    parameter RECIP      = 4681
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  en,
    input  wire [DATA_WIDTH-1:0] new_sample,   // newest price (Q16.16)
    input  wire [DATA_WIDTH-1:0] old_sample,   // price falling off (Q16.16)
    output reg  [DATA_WIDTH-1:0] sma_out,      // result (Q16.16)
    output reg                   valid          // high when output is ready
);
 
    // Use 64-bit accumulator to avoid overflow when summing 50 x Q16.16 values
    // 50 * (max price ~$10000) * 65536 fits in ~49 bits → 64 bit is safe
    reg [63:0] running_sum;
 
    always @(posedge clk) begin
        if (rst) begin
            running_sum <= 0;
            sma_out     <= 0;
            valid       <= 0;
        end
        else if (en) begin
            // Update sum: add new, remove old
            running_sum <= running_sum + new_sample - old_sample;
 
            // Multiply sum by reciprocal, then shift right by 16
            // This gives: (sum / DEPTH) in Q16.16 format
            // sum is Q16.16, RECIP is Q0.16 → product is Q16.32 → shift >>16 gives Q16.16
            sma_out <= (running_sum * RECIP) >> 16;
 
            valid <= 1;
        end
        else begin
            valid <= 0;
        end
    end
endmodule
