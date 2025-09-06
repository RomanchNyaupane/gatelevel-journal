module cordic (
    input wire signed [31:0] angle,
    input wire clk, reset,
    output reg signed [31:0] x, y
);

parameter STAGES = 6;
reg signed [31:0] x_reg [0:STAGES];
reg signed [31:0] y_reg [0:STAGES];
reg signed [31:0] z_reg [0:STAGES];

reg [1:0] quadrant_flag [0:STAGES];
reg signed [31:0] mapped_angle;

reg signed [31:0] atan_table [0:STAGES];
initial begin
    atan_table[0] = 32'sd8192;//45
    atan_table[1] = 32'sd4830;//26.565
    atan_table[2] = 32'sd2556;//14.036
    atan_table[3] = 32'sd1298;//7.125
    atan_table[4] = 32'sd651;//3.576
    atan_table[5] = 32'sd326;//1.79
    atan_table[6] = 32'sd163;//0.895
end

//quadrant mapping, initialization
always @(posedge clk) begin
    if (reset) begin
        x_reg[0] <= 32'sd0;
        y_reg[0] <= 32'sd0;
        z_reg[0] <= 32'sd0;
        quadrant_flag[0] <= 2'b00;
    end else begin
        if (angle >= 0 && angle <= 32'sd16386) begin //0 to 90 - 1st quadrant
            mapped_angle <= angle;
            quadrant_flag[0] <= 2'b00;
        end else if (angle > 32'sd16386 && angle <= 32'sd32768) begin //90 to 180 - 2nd quadrant
            mapped_angle <= 32'sd32768 - angle; //180 - angle
            quadrant_flag[0] <= 2'b01;
        end else if (angle > 32'sd32768 && angle <= 32'sd49151) begin //180 to 270 - 3rd quadrant
            mapped_angle <= angle - 32'sd32768; //angle - 180
            quadrant_flag[0] <= 2'b10;
        end else begin //270 to 360 - 4th quadrant
            mapped_angle <= 32'sd65535 - angle; // 360 - angle
            quadrant_flag[0] <= 2'b11;
        end
        
        x_reg[0] <= 32'sd256;
        y_reg[0] <= 32'sd0;
        z_reg[0] <= mapped_angle;
    end
end

genvar i;
generate for (i = 0; i < STAGES; i = i + 1) begin : cordic_stages
    always @(posedge clk) begin
        if (reset) begin
            x_reg[i+1] <= 32'sd0;
            y_reg[i+1] <= 32'sd0;
            z_reg[i+1] <= 32'sd0;
            quadrant_flag[i+1] <= 2'b00;
        end else begin
            quadrant_flag[i+1] <= quadrant_flag[i];
            
            if (z_reg[i][31]) begin //z_reg[i] < 0
                x_reg[i+1] <= x_reg[i] + (y_reg[i] >>> i);
                y_reg[i+1] <= y_reg[i] - (x_reg[i] >>> i);
                z_reg[i+1] <= z_reg[i] + atan_table[i];
            end else begin //z_reg[i] >= 0
                x_reg[i+1] <= x_reg[i] - (y_reg[i] >>> i);
                y_reg[i+1] <= y_reg[i] + (x_reg[i] >>> i);
                z_reg[i+1] <= z_reg[i] - atan_table[i];
            end
        end
    end
end
endgenerate

//output, quadrant correction
always @(posedge clk) begin
    if (reset) begin
        x <= 32'sd0;
        y <= 32'sd0;
    end else begin
        case (quadrant_flag[STAGES])
            2'b00: begin //1st quadrant - 0 to 90
                x <= x_reg[STAGES];
                y <= y_reg[STAGES];
            end
            2'b01: begin //2nd quadrant - 90 to 180
                x <= -x_reg[STAGES];
                y <= y_reg[STAGES];
            end
            2'b10: begin //3rd quadrant - 180 to 270
                x <= -x_reg[STAGES];
                y <= -y_reg[STAGES];
            end
            2'b11: begin //4th quadrant - 270 to 360
                x <= x_reg[STAGES];
                y <= -y_reg[STAGES];
            end
        endcase
    end
end

endmodule
