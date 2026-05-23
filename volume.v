module volume_filter #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH      = 20,
    parameter RECIP_20   = 3277,    // 1/20 in Q0.16
    parameter THRESH_Q   = 98304    // 1.5 in Q16.16
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  en,
    input  wire [DATA_WIDTH-1:0] vol_in,
    output wire [DATA_WIDTH-1:0] avg_vol_out,
    output reg                   vol_spike
);
 
    reg [DATA_WIDTH-1:0] vol_mem [0:DEPTH-1];
    reg [63:0]           vol_sum;
    integer i;
 
    // Running 20-period average (Q16.16)
    wire [DATA_WIDTH-1:0] avg_vol = (vol_sum * RECIP_20) >> 16;
    assign avg_vol_out = avg_vol;
 
    // Threshold = 1.5 * avg_vol  (both in Q16.16)
    // avg_vol is Q16.16, THRESH_Q is Q16.16
    // product is Q32.32 → shift >>16 gives Q16.16
    wire [63:0] threshold_64 = (avg_vol * THRESH_Q) >> 16;
    wire [DATA_WIDTH-1:0] threshold = threshold_64[DATA_WIDTH-1:0];
 
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < DEPTH; i = i + 1)
                vol_mem[i] <= 0;
            vol_sum   <= 0;
            vol_spike <= 0;
        end
        else if (en) begin
            // Update running sum
            vol_sum <= vol_sum + vol_in - vol_mem[DEPTH-1];
 
            // Shift history
            for (i = DEPTH-1; i > 0; i = i - 1)
                vol_mem[i] <= vol_mem[i-1];
            vol_mem[0] <= vol_in;
 
            // ✅ FIXED: correct 1.5x threshold check
            vol_spike <= (vol_in > threshold) ? 1'b1 : 1'b0;
        end
    end
 
endmodule
