`timescale 1ns/1ps

module cordic_tb;

// Parameters
parameter CLK_PERIOD = 10;  // 100 MHz clock
parameter STAGES = 6;
parameter K = 256;          // CORDIC scaling factor (0.607 * 2^9)

// Signals
reg clk;
reg reset;
reg [15:0] angle;
wire [15:0] x_out, y_out;

// Instantiate DUT
cordic dut (
    .angle(angle),
    .clk(clk),
    .reset(reset),
    .x(x_out),
    .y(y_out)
);

// Clock generation
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

// Angle to degrees conversion function
function real angle_to_degrees;
    input [15:0] angle;
    begin
        // Convert 16-bit fixed-point to degrees (360° = 65536)
        angle_to_degrees = $itor(angle) * 360.0 / 65536.0;
    end
endfunction

// CORDIC output to real value conversion
function real cordic_to_real;
    input [15:0] val;
    begin
        cordic_to_real = $itor(val) / $itor(K);
    end
endfunction

// Test cases
task test_angle;
    input [15:0] test_angle;
    real expected_cos, expected_sin;
    real angle_deg;
    begin
        angle = test_angle;
        angle_deg = angle_to_degrees(angle);
        expected_cos = $cos(angle_deg * 3.1415926/180.0);
        expected_sin = $sin(angle_deg * 3.1415926/180.0);
        
        #(CLK_PERIOD * (STAGES + 2));  // Wait for pipeline
        
        $display("Angle: %5.1f° (0x%4h)", angle_deg, angle);
        $display("  X (cos): %8.4f (0x%4h) | Expected: %8.4f", 
                 cordic_to_real(x_out), x_out, expected_cos);
        $display("  Y (sin): %8.4f (0x%4h) | Expected: %8.4f", 
                 cordic_to_real(y_out), y_out, expected_sin);
        $display("");
    end
endtask

// Main test sequence
initial begin
    // Initialize
    reset = 1;
    angle = 0;
    #(CLK_PERIOD*2) reset = 0;
    
    $display("Starting CORDIC Testbench");
    $display("-----------------------");
    
    // Test cases
    test_angle(16'h0000);    // 0°
    test_angle(16'h2000);    // 45°
    test_angle(16'h4000);    // 90°
    test_angle(16'h6000);    // 135°
    test_angle(16'h8000);    // 180°
    test_angle(16'hA000);    // 225°
    test_angle(16'hC000);    // 270°
    test_angle(16'hE000);    // 315°
    test_angle(16'h0B60);    // ~25°
    test_angle(16'hFEDC);    // ~-5°
    
    // Edge cases
    test_angle(16'hFFFF);    // ~-0.0055°
    test_angle(16'h7FFF);    // ~179.994°
    
    $display("Testbench completed");
    $finish;
end

// Waveform dumping (for debugging)
initial begin
    $dumpfile("cordic_tb.vcd");
    $dumpvars(0, cordic_tb);
end

endmodule