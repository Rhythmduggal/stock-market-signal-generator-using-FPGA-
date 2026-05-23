module shift_reg #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH      = 14
)(
    input  wire                          clk,
    input  wire                          rst,
    input  wire                          en,
    input  wire [DATA_WIDTH-1:0]         data_in,
    output wire [DATA_WIDTH*DEPTH-1:0]   data_out_flat   // flattened output
);
 
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    integer i;
 
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < DEPTH; i = i + 1)
                mem[i] <= 0;
        end
        else if (en) begin
            // Shift: mem[0] = newest, mem[DEPTH-1] = oldest
            for (i = DEPTH-1; i > 0; i = i - 1)
                mem[i] <= mem[i-1];
            mem[0] <= data_in;
        end
    end
 
    // Flatten memory array to output bus
    genvar j;
    generate
        for (j = 0; j < DEPTH; j = j + 1) begin : flatten
            assign data_out_flat[j*DATA_WIDTH +: DATA_WIDTH] = mem[j];
        end
    endgenerate
 
endmodule
