module FPU_tb;
    reg [31:0] FP_in1, FP_in2;
    reg calc_mode;
    reg [1:0] round_mode;
    reg clk, reset;
    wire [31:0] FP_result;
    FPU uut (
        .FP_in1(FP_in1),
        .FP_in2(FP_in2),
        .calc_mode(calc_mode),
        .round_mode(round_mode),
        .clk(clk),
        .reset(reset),
        .FP_result(FP_result)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        reset = 1;
        FP_in1 = 0;
        FP_in2 = 0;
        calc_mode = 0;
        round_mode = 0;
        #20 reset = 0;  //set reset to 0 after 20ns
        
        @(posedge clk);
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h3f800000, 32'h40000000, 1'b0, 2'b00}; //1 + 2 = 3

        @(posedge clk);
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h40a00000, 32'h40200000, 1'b1, 2'b00}; //5 - 2.5 = 2.5
        
        @(posedge clk);
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h3f000000, 32'h3e800000, 1'b0, 2'b00};//0.5 + 0.25 = 0.75
        
        @(posedge clk);
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h3f800000, 32'h00000000, 1'b0, 2'b00};//1 + 0 = 1
        
        @(posedge clk);
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h00000000, 32'h3f800000, 1'b1, 2'b00};//0- 1 = -1
        
        @(posedge clk);
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h80000000, 32'h00000000, 1'b0, 2'b00};//-0 + 0 = 0
        
        @(posedge clk);
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h49742400, 32'h4a189680, 1'b0, 2'b00};//1e6 + 2e6 = 3e6
        
        @(posedge clk);
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h49742400, 32'h3f800000, 1'b1, 2'b00};//1e6 - 1 = 999999

        @(posedge clk);
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h00800000, 32'h00800000, 1'b0, 2'b00};//1.1754944e-38 + 1.1754944e-38 = 2.3509887e-38

        @(posedge clk);
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h3f800000, 32'h00000001, 1'b0, 2'b00};//1.0 + tiny = 1.0
       
        @(posedge clk);
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h3fc00000, 32'h3fc00000, 1'b0, 2'b00};//1.5 + 1.5(round to nearest even)

       
        @(posedge clk);
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h3fc00000, 32'h3fc00000, 1'b0, 2'b01};//round toward zero
        
        @(posedge clk);
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h7f7fffff, 32'h7f7fffff, 1'b0, 2'b00};//max normal + max normal(overflow)

        @(posedge clk);
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h00800000, 32'h00800000, 1'b1, 2'b00};//min normal - min normal



        @(posedge clk);
        //wait for pipeline flush
        repeat(10) @(posedge clk);
        $finish;
    end
    
    initial begin
        $dumpfile("fpu_waves.vcd");
        $dumpvars(0, FPU_tb);
        $monitor("At %t: in1=%h in2=%h op=%b rm=%b => out=%h",
                 $time, FP_in1, FP_in2, calc_mode, round_mode, FP_result);
    end
endmodule