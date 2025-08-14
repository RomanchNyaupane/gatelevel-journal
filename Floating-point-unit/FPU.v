`include "subnormal_detection.v"
`include "prenormalization.v"
`include "postnormalization.v"

module FPU(
    input wire [31:0] FP_in1, FP_in2,
    input wire calc_mode,           // 0 for addition, 1 for subtraction
    input wire [1:0] round_mode,
    input wire clk, reset,

    output reg [31:0] FP_result,
    output reg res1,
    output reg res2,
    output reg [2:0] optype
);
wire is_subnormal1, is_subnormal2;
wire [23:0] normalized_mantissa1, normalized_mantissa2;
wire [7:0] main_exponent;
wire [31:0] out;

subnormal_detection subnorm_in1(
    .FP_in(FP_in1),
    .is_subnormal(is_subnormal1)
);
subnormal_detection subnorm_in2(
    .FP_in(FP_in2),
    .is_subnormal(is_subnormal2)
);
prenormalization prenorm(
    .FP_in1(S_01_FP_in1),
    .FP_in2(S_01_FP_in2),
    .calc_mode(calc_mode),
    .clk(clk),
    .subnormal_status({is_subnormal1, is_subnormal2}),
    .FP_norm1(normalized_mantissa1),// Assuming prenormalization outputs 24 bits 
    .FP_norm2(normalized_mantissa2),// Assuming prenormalization outputs 24 bits
    .main_exponent(main_exponent)
);
postnormalization postnorm(
    .result_sign(S_23_FP_result[25]),
    .extra_exponent(S_23_FP_result[24]),
    .main_exponent(S_23_main_exponent),
    .first_exponent(S_23_FP_result[23]),
    .FP_result(S_23_FP_result[22:0]),
    .round_mode(S_23_round_mode),
    .FP_out(out),
    .clk(clk)
);

reg [1:0] S_01_round_mode;
reg S_01_calc_mode, S_01_is_subnormal1, S_01_is_subnormal2;
reg [31:0] S_01_FP_in1, S_01_FP_in2;
reg [23:0] S_01_norm_mantissa1, S_01_norm_mantissa2;

reg [1:0] S_12_round_mode;
reg S_12_calc_mode, S_12_is_subnormal1, S_12_is_subnormal2;
reg [23:0] S_12_norm_mantissa1, S_12_norm_mantissa2;
reg [7:0] S_12_main_exponent;
reg S_12_FP_1_sign, S_12_FP_2_sign; // Sign bits of the inputs

reg [25:0] S_23_FP_result;  //26th bit is 1 if sign of result is negative
reg [1:0] S_23_round_mode;
reg [7:0] S_23_main_exponent;

reg [22:0] S_34_FP_result; // 26 bits to hold the result after rounding
reg [7:0] S_34_main_exponent;
reg S_34_result_sign;
reg S_34_first_exponent;
reg S_34_extra_exponent;

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
//    S_12_norm_mantissa1 <= normalized_mantissa1;
//    S_12_norm_mantissa2 <= normalized_mantissa2;
    S_12_main_exponent <= main_exponent;

//stage 2-3
    //subtraction
    case ({S_12_calc_mode,S_12_FP_1_sign, S_12_FP_2_sign})
        3'b100 : begin S_23_FP_result <= {1'b0, normalized_mantissa1} - {1'b0, normalized_mantissa2}; optype <= 3'b100; end//both are positive
        3'b101 : begin S_23_FP_result <= {1'b0, normalized_mantissa1} + {1'b0, normalized_mantissa2}; optype <= 3'b101; end //FP_in1 is positive, FP_in2 is negative
        3'b110 : begin
                S_23_FP_result <= {1'b0, normalized_mantissa1} + {1'b0, normalized_mantissa2}; //FP_in1 is negative, FP_in2 is positive
                S_23_FP_result[25] <= 1'b1; // Result is negative
                optype <= 3'b110;
            end
        3'b111 : begin S_23_FP_result <= {1'b0, normalized_mantissa2} - {1'b0, normalized_mantissa1}; optype <= 3'b111; end //both are negative
    //addition
        3'b000 : begin S_23_FP_result <= normalized_mantissa1 + normalized_mantissa2; optype <= 3'b000; end //both are positive
        3'b001 : begin S_23_FP_result <= {1'b0, normalized_mantissa1} - {1'b0, normalized_mantissa2}; optype <= 3'b001; end//FP_in1 is positive, FP_in2 is negative
        3'b010 : begin S_23_FP_result <= {1'b0, normalized_mantissa2} - {1'b0, normalized_mantissa1}; optype <= 3'b010; end //FP_in1 is negative, FP_in2 is positive
        3'b011 : begin
                    S_23_FP_result <= {1'b0, normalized_mantissa2} + {1'b0, normalized_mantissa1}; //both are negative
                    S_23_FP_result[25] <= 1'b1; // Result is negative
                    optype <= 3'b011;
                 end

        default: begin 
            S_23_FP_result <= 26'b0;
        end 
    endcase 

    S_23_round_mode <= S_12_round_mode;
    S_23_main_exponent <= main_exponent;

    //stage 3-4
    FP_result <= out;

end



endmodule