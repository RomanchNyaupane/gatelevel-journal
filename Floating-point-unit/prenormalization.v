module prenormalization(
    input wire [31:0] FP_in1, FP_in2,
    input wire calc_mode,
    input wire clk,
    input wire [1:0] subnormal_status,

    output reg [23:0] FP_norm1, FP_norm2//, res
);
wire compare_exponents = (FP_in1[30:23] < FP_in2[30:23])? 1'b1 : 1'b0;
wire [7:0] exp_diff = compare_exponents ? (FP_in2[30:23] - FP_in1[30:23]) : (FP_in1[30:23] - FP_in2[30:23]);
always @(posedge clk) begin
    case(subnormal_status)
        2'b00: begin
            if(compare_exponents) begin
                FP_norm1[23:0] <= (({1'b1,FP_in1[22:0]}) >> exp_diff);
                FP_norm2[23:0] <= {1'b1, FP_in2[22:0]};
            end else begin
                FP_norm2[23:0] <= (({1'b1,FP_in2[22:0]}) >> exp_diff);
                FP_norm1[23:0] <= {1'b1, FP_in1[22:0]};
            end 
        end

        2'b01: begin    // only FP_in1 is subnormal
            FP_norm1[22:0] <= FP_in1[22:0];
            FP_norm2[22:0] <= (FP_in2[22:0] >> exp_diff);
            FP_norm1[23] <= 1'b0;
            FP_norm2[23] <= 1'b1;
        end
        2'b10: begin    // only FP_in2 is subnormal
            FP_norm1[22:0] <= FP_in1[22:0];
            FP_norm2[22:0] <= FP_in2[22:0];
            FP_norm1[23] <= 1'b1;
            FP_norm2[23] <= 1'b0;
        end
        2'b11: begin    // both inputs are subnormal
            FP_norm1[22:0] <= FP_in1[22:0];
            FP_norm2[22:0] <= FP_in2[22:0];
            FP_norm1[23] <= 1'b0;
            FP_norm2[23] <= 1'b0;
        end
        default: begin
            FP_norm1 <= 23'b0;
            FP_norm2 <= 23'b0;
        end
    endcase
end



endmodule