module cordic (
    input wire signed [15:0] angle,
    input wire clk, reset,
    output reg signed [15:0] x, y
);

parameter STAGES = 6;
reg signed [15:0] x_reg [0:STAGES];
reg signed [15:0] y_reg [0:STAGES];
reg signed [15:0] z_reg [0:STAGES];

reg signed [15:0] atan_table [0:STAGES];
initial begin
    atan_table[0] = 16'sd11520;//45.0°
    atan_table[1] = 16'sd6805;//26.565°
    atan_table[2] = 16'sd3593;//14.036°
    atan_table[3] = 16'sd1824;//7.125°
    atan_table[4] = 16'sd915; //3.576°
    atan_table[5] = 16'sd458; //1.790°
    atan_table[6] = 16'sd229; //0.895°
end

always @(posedge clk) begin
    if (reset) begin
            x_reg[0] <= 16'sd0;
            y_reg[0] <= 16'sd0;
            z_reg[0] <= 16'sd0;
    end else begin
        x_reg[0] <= 16'sd256; 
        y_reg[0] <= 16'sd0;
        z_reg[0] <= angle;
   end
        x <= x_reg[6];
        y <= y_reg[6];
end

genvar i;
generate for (i = 0; i < STAGES; i = i + 1) begin : cordic_stages
    always @(posedge clk) begin
        if (reset) begin
            x_reg[i+1] <= 16'sd0;
            y_reg[i+1] <= 16'sd0;
            z_reg[i+1] <= 16'sd0;
        end else begin
            if (z_reg[i][15]) begin  
                x_reg[i+1] <= x_reg[i] + (y_reg[i] >>> i);
                y_reg[i+1] <= y_reg[i] - (x_reg[i] >>> i);
                z_reg[i+1] <= z_reg[i] + atan_table[i];
            end else begin           
                x_reg[i+1] <= x_reg[i] - (y_reg[i] >>> i);
                y_reg[i+1] <= y_reg[i] + (x_reg[i] >>> i);
                z_reg[i+1] <= z_reg[i] - atan_table[i];
            end
        end
    end
end endgenerate

endmodule
