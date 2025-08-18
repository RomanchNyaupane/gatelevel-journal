module pipeline_tb;
    reg [3:0] rs1, rs2, rd, func;
    reg [7:0] addr;
    reg clk1, clk2;

    wire [15:0] z_out;
    integer k;
    pipeline_example uut (
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .func(func),
        .addr(addr),
        .clk1(clk1),
        .clk2(clk2),
        .z_out(z_out)
    );
    initial begin
        repeat(20) begin
        #5 clk1 = 1; #5 clk1 = 0;
        #5 clk2 = 1; #5 clk2 = 0;
        end
    end
    initial
    for (k=0; k<20; k=k+1 ) begin
        pipeline_example.register_bank[k] = k;
    end
    
    initial begin
    #5 rs1 = 3; rs2 = 5; rd = 10; func = 1; addr = 125;
    #20 rs1 = 3; rs2 = 8; rd = 12; func = 2; addr = 126;
    #20 rs1 = 10; rs2 = 5; rd = 14; func = 3; addr = 128;
    #20 rs1 = 17; rs2 = 3; rd = 13; func = 4; addr = 127;
    
    #60 for(k=125; k<131; k=k+1)
        $display("mem[%3d] = %3d", k, pipeline_example.memory[k]);
    end
    
    initial begin
        $dumpfile("pipeline_tb.vcd");
        $dumpvars(0, pipeline_tb);
        $monitor("time: %3d , F = %3d", $time, z_out);
        #300 $finish;
    end
endmodule