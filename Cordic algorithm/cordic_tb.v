`timescale 1ns/100ps
module cordic_tb;
//declare register and wires for connecting with DUT
reg signed [31:0] angle;
reg clk, reset;
wire [31:0] x,y;

reg signed [31:0] test_angles [0:24];
integer i,j;
//instantiate the DUT
cordic cord_inst(
    .angle(angle),
    .clk(clk),
    .reset(reset),
    .x(x), .y(y)
);

//initialize and generate clock
initial clk = 0;
always #5 clk = ~clk;

task inp_prov;
    input signed [31:0] task_angle;
    
    begin
    angle = task_angle;
    #10;
    $display("%0t | %h %h %d",$time, angle, x, y);
    end

endtask
initial begin
    test_angles[0] = 32'sd0000; //0
    test_angles[1] = 32'sd2731; //15
    test_angles[2] = 32'sd5461; //30
    test_angles[3] = 32'sd8192; //45
    test_angles[4] = 32'sd10923;//60
    test_angles[5] = 32'sd13654;//75
    test_angles[6] = 32'sd16386;//90
    test_angles[7] = 32'sd19115;//105
    test_angles[8] = 32'sd21846;//120
    test_angles[9] = 32'sd24576;//135
    test_angles[10] = 32'sd27307;//150
    test_angles[11] = 32'sd30038;//165
    test_angles[12] = 32'sd32768;//180
    
    test_angles[13] = 32'sd35499;//15 + 180
    test_angles[14] = 32'sd38230;//30 + 180
    test_angles[15] = 32'sd40960;//45 + 180
    test_angles[16] = 32'sd43691;//60 + 180
    test_angles[17] = 32'sd46422;//75 + 180
    test_angles[18] = 32'sd49151;//90 + 180
    test_angles[19] = 32'sd51883;//105 + 180
    test_angles[20] = 32'sd54613;//120 + 180
    test_angles[21] = 32'sd57344;//135 + 180
    test_angles[22] = 32'sd60075;//150 + 180
    test_angles[23] = 32'sd62806;//165 + 180
    test_angles[24] = 32'sd65535;//180 + 180
end
//input stimulus
initial begin
    angle = 32'sd0000;
    reset = 1;
    
    #20 reset = 0;
    
    @(posedge clk);
    for(i=0; i<5; i = i+1) begin
        for(j=0; j<=24; j = j+1) begin
            inp_prov(test_angles[j]);
        end    
    end
    $finish;
    
end

initial begin
    $dumpfile("cordic_tb.vcd");
    $dumpvars(0, cordic_tb);
end

endmodule

