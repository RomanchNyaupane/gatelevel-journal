module FPU_tb;
    // Inputs
    reg [31:0] FP_in1, FP_in2;
    reg calc_mode;
    reg [1:0] round_mode;
    reg clk, reset;
    
    // Output
    wire [31:0] FP_result;
    
    // Instantiate the FPU
    FPU uut (
        .FP_in1(FP_in1),
        .FP_in2(FP_in2),
        .calc_mode(calc_mode),
        .round_mode(round_mode),
        .clk(clk),
        .reset(reset),
        .FP_result(FP_result)
    );
    
    // Clock generation (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test sequence
    initial begin
        // Initialize and reset
        reset = 1;
        FP_in1 = 0;
        FP_in2 = 0;
        calc_mode = 0;
        round_mode = 0;
        #20 reset = 0;
        
        // Apply new test case every clock cycle
        @(posedge clk);
        
        // Group 1: Basic arithmetic
        // 1.0 + 2.0 = 3.0
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h3f800000, 32'h40000000, 1'b0, 2'b00};
        @(posedge clk);
        
        // 5.0 - 2.5 = 2.5
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h40a00000, 32'h40200000, 1'b1, 2'b00};
        @(posedge clk);
        
        // 0.5 + 0.25 = 0.75
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h3f000000, 32'h3e800000, 1'b0, 2'b00};
        @(posedge clk);
        
        // Group 2: Special values
        // 1.0 + 0.0 = 1.0
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h3f800000, 32'h00000000, 1'b0, 2'b00};
        @(posedge clk);
        
        // 0.0 - 1.0 = -1.0
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h00000000, 32'h3f800000, 1'b1, 2'b00};
        @(posedge clk);
        
        // -0.0 + 0.0 = 0.0
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h80000000, 32'h00000000, 1'b0, 2'b00};
        @(posedge clk);
        
        // Group 3: Large numbers
        // 1e6 + 2e6 = 3e6
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h49742400, 32'h4a189680, 1'b0, 2'b00};
        @(posedge clk);
        
        // 1e6 - 1.0 = 999999
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h49742400, 32'h3f800000, 1'b1, 2'b00};
        @(posedge clk);
        
        // Group 4: Small numbers
        // 1.1754944e-38 + 1.1754944e-38 = 2.3509887e-38
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h00800000, 32'h00800000, 1'b0, 2'b00};
        @(posedge clk);
        
        // 1.0 + tiny = 1.0 (due to precision)
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h3f800000, 32'h00000001, 1'b0, 2'b00};
        @(posedge clk);
        
        // Group 5: Rounding modes
        // 1.5 + 1.5 (round to nearest even)
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h3fc00000, 32'h3fc00000, 1'b0, 2'b00};
        @(posedge clk);
        
        // Same with round toward zero
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h3fc00000, 32'h3fc00000, 1'b0, 2'b01};
        @(posedge clk);
        
        // Group 6: Edge cases
        // Max normal + max normal (overflow)
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h7f7fffff, 32'h7f7fffff, 1'b0, 2'b00};
        @(posedge clk);
        
        // Min normal - min normal
        {FP_in1, FP_in2, calc_mode, round_mode} = {32'h00800000, 32'h00800000, 1'b1, 2'b00};
        @(posedge clk);
        
        // Wait for pipeline to flush
        repeat(10) @(posedge clk);
        $finish;
    end
    
    // Monitoring
    initial begin
        $dumpfile("fpu_waves.vcd");
        $dumpvars(0, FPU_tb);
        $monitor("At %t: in1=%h in2=%h op=%b rm=%b => out=%h",
                 $time, FP_in1, FP_in2, calc_mode, round_mode, FP_result);
    end
endmodule