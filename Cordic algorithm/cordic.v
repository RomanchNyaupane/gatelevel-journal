        module cordic (
            input wire [15:0] angle,
            input wire clk, reset,
            output reg [15:0] x, y
        );
        reg [15:0] x_reg, y_reg, z_reg;
        reg [15:0] x_reg_1, y_reg_1, z_reg_1;
        reg [2:0] iteration;
        reg comparator;
        
        reg [15:0] tan_table;
        
        
        always @(posedge clk) begin
            if (reset) begin
                x_reg <= 16'd256;
                y_reg <= 16'b0; x_reg_1<= 16'b0; y_reg_1<= 16'b0;
                z_reg_1 <= 16'b0;
                z_reg <= angle;
                iteration <= 3'b000;
            end else begin  
            

                
                if(!comparator) begin
                    x_reg <= x_reg - (y_reg >> iteration);
                    y_reg <= y_reg + (x_reg >> iteration);
                    z_reg <= z_reg - (tan_table);
                end else begin
                    x_reg <= x_reg + (y_reg >> iteration);
                    y_reg <= y_reg - (x_reg >> iteration);
                    z_reg <= z_reg + (tan_table);
                end
        
                if(iteration < 3'd7) 
                    iteration <= iteration + 1;
                 else 
                    iteration <= 3'd0;
                    x <= x_reg ;
                    y <= y_reg ;
                end
                
        end
        
        always @(*) begin
        
             if (z_reg[15:14] == 2'b11)
                comparator <= 1'b1;
            else
                comparator <= 1'b0;
                
            case (iteration)
                3'd0: tan_table = 16'd11520; // 45.0000°
                3'd1: tan_table = 16'd6805;  // 26.5651°
                3'd2: tan_table = 16'd3593;  // 14.0362°
                3'd3: tan_table = 16'd1824;  // 7.1250°
                3'd4: tan_table = 16'd915;   // 3.5763°
                3'd5: tan_table = 16'd458;   // 1.7899°
                3'd6: tan_table = 16'd229;   // 0.8952°
                default: tan_table = 16'd0;
            endcase
        end
        
        
        endmodule
        
