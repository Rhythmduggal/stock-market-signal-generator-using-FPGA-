`timescale 1ns / 1ps
 
module tb_stock_signal;
 
    parameter DATA_WIDTH = 32;
    parameter CLK_PERIOD = 10;
 
    reg                   clk, rst, en;
    reg  [DATA_WIDTH-1:0] price_in, volume_in;
 
    wire [1:0]  signal_out;
    wire        signal_valid;
    wire [2:0]  led;
 
    stock_signal_top #(.DATA_WIDTH(DATA_WIDTH)) dut (
        .clk(clk), .rst(rst), .en(en),
        .price_in(price_in), .volume_in(volume_in),
        .signal_out(signal_out), .signal_valid(signal_valid),
        .led(led)
    );
 
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;
 
    // Send one sample
    task send_sample;
        input integer price, volume;
        begin
            price_in  = price  << 16;
            volume_in = volume << 16;
            en = 1; @(posedge clk); #1;
            en = 0; @(posedge clk); #1;
        end
    endtask
 
    // Print every step
    task print_signal;
        input integer step, price;
        begin
            $write("Step %3d  px=%3d  EMA14=%6.1f  EMA50=%6.1f  RSI=%5.1f  |  ",
                step, price,
                dut.ema14_out / 65536.0,
                dut.ema50_out / 65536.0,
                dut.rsi_out   / 65536.0);
            case (signal_out)
                2'b01: $display(">>> BUY  <<<");
                2'b10: $display(">>> SELL <<<");
                2'b00: $display("    hold");
                default: $display("????");
            endcase
        end
    endtask
 
    integer k, pv;
 
    initial begin
        rst=1; en=0; price_in=0; volume_in=0;
        repeat(5) @(posedge clk);
        rst=0; @(posedge clk);
 
        $display("=== SIMULATION START ===");
        $display("Watch EMA14 and EMA50 - BUY fires when EMA14 crosses above EMA50");
        $display("");
 
        // Phase 1: downtrend 200->101 (100 steps)
        $display("--- PHASE 1: Downtrend 200->101 ---");
        for (k=0; k<100; k=k+1) begin
            pv = 200 - k;
            send_sample(pv, 1000000);
            print_signal(k, pv);
        end
 
        // Phase 2: uptrend 50->248 step=2 (100 steps)
        $display("");
        $display("--- PHASE 2: Uptrend 50->248 (step +2) ---");
        for (k=0; k<100; k=k+1) begin
            pv = 50 + k*2;
            send_sample(pv, 2000000);
            print_signal(k+100, pv);
        end
 
        // Phase 3: downtrend 250->171 (80 steps)
        $display("");
        $display("--- PHASE 3: Downtrend 250->171 ---");
       // NEW - steeper drop, step=-2
for (k=0; k<100; k=k+1) begin
    pv = 250 - k*2;
    if (pv < 20) pv = 20;   // floor so price doesn't go negative
    send_sample(pv, 1000000);
    print_signal(k+200, pv);
end
 
        $display("=== DONE ===");
        $finish;
    end
 
    initial begin
        $dumpfile("stock_signal.vcd");
        $dumpvars(0, tb_stock_signal);
    end
 
endmodule
