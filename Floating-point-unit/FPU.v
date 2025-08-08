module FPU(
    input wire [31:0] FP_in1, FP_in2,
    input wire calc_mode,           //  // 0 for addition, 1 for subtraction
    input wire [1:0] round_mode,
    input wire clk, reset,

    output reg [31:0] FP_result,
);
wire is_subnormal1, is_subnormal2;
wire [23:0] normalized_mantissa1, normalized_mantissa2;

.subnormal_detection subnorm_in1(
    .FP_in(FP_in1),
    .is_subnormal(is_subnormal1),
    .clk(clk)
);
.subnormal_detection subnorm_in2(
    .FP_in(FP_in2),
    .is_subnormal(is_subnormal2),
    .clk(clk)
);
.prenormalization prenorm(
    .FP_in1(FP_in1),
    .FP_in2(FP_in2),
    .calc_mode(calc_mode),
    .clk(clk),
    .subnormal_status({is_subnormal1, is_subnormal2}),
    .FP_norm1(normalized_mantissa1),// Assuming prenormalization outputs 24 bits 
    .FP_norm2(normalized_mantissa2)// Assuming prenormalization outputs 24 bits 
);



reg [1:0] S_01_round_mode;
reg S_01_calc_mode, S_01_is_subnormal1, S_01_is_subnormal2;
reg [31:0] S_01_FP_in1, S_01_FP_in2;
reg [23:0] S_01_norm_mantissa1, S_01_norm_mantissa2;

reg [1:0] S_12_round_mode;
reg S_12_calc_mode, S_12_is_subnormal1, S_12_is_subnormal2;
reg [23:0] S_12_norm_mantissa1, S_12_norm_mantissa2;
reg S_12_FP_1_sign, S_12_FP_2_sign; // Sign bits of the inputs

reg [25:0] S_23_FP_result;  //26th bit is 1 if sign of result is negative
reg 



always @ (posedge clk) begin
//stage 0-1
    S_01_is_subnormal1 <= is_subnormal1;
    S_01_is_subnormal2 <= is_subnormal2;
    S_01_round_mode <= round_mode;
    S_01_calc_mode <= calc_mode;
    S_01_FP_in1 <= FP_in1;
    S_01_FP_in2 <= FP_in2;

//stage 1-2
    //S_12_is_subnormal1 <= S_01_is_subnormal1;
    //S_12_is_subnormal2 <= S_01_is_subnormal2;
    S_12_FP_1_sign <= S_01_FP_in1[31];
    S_12_FP_2_sign <= S_01_FP_in2[31];  
    S_12_round_mode <= S_01_round_mode;
    S_12_calc_mode <= S_01_calc_mode;
    S_12_norm_mantissa1 <= normalized_mantissa1;
    S_12_norm_mantissa2 <= normalized_mantissa2;

//stage 2-3
    //subtraction
    case ({S_12_calc_mode,S_12_FP_1_sign, S_12_FP_2_sign})
        3'b100 : S_23_FP_result <= {1'b0, S_12_norm_mantissa1} - {1'b0, S_12_norm_mantissa2}; //both are positive
        3'b101 : S_23_FP_result <= {1'b0, S_12_norm_mantissa1} + {1'b0, S_12_norm_mantissa2}; //FP_in1 is positive, FP_in2 is negative
        3'b110 : begin
                S_23_FP_result <= {1'b0, S_12_norm_mantissa1} + {1'b0, S_12_norm_mantissa2}; //FP_in1 is negative, FP_in2 is positive
                S_23_FP_result[25] <= 1'b1; // Result is negative
            end
        3'b111 : S_23_FP_result <= {1'b0, S_12_norm_mantissa2} - {1'b0, S_12_norm_mantissa1}; //both are negative
    //ad3ition
        3'b000 : S_23_FP_result <= {1'b0, S_12_norm_mantissa1} + {1'b0, S_12_norm_mantissa2}; //both are positive
        3'b001 : S_23_FP_result <= {1'b0, S_12_norm_mantissa1} - {1'b0, S_12_norm_mantissa2}; //FP_in1 is positive, FP_in2 is negative
        3'b010 : S_23_FP_result <= {1'b0, S_12_norm_mantissa2} - {1'b0, S_12_norm_mantissa1}; //FP_in1 is negative, FP_in2 is positive
        3'b011 : begin
                S_23_FP_result <= {1'b0, S_12_norm_mantissa2} + {1'b0, S_12_norm_mantissa1}; //both are negative
                S_23_FP_result[25] <= 1'b1; // Result is negative
        end

        default: begin
            S_23_FP_result <= 26'b0; // Default case, should not happen
        end
    endcase



end
endmodule