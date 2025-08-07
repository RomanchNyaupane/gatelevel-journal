module FPU(
    input wire [31:0] FP_in1, FP_in2,
    input wire calc_mode,
    input wire [1:0] round_mode,
    input wire clk, reset,

    output reg [31:0] FP_result,
);
wire is_subnormal1, is_subnormal2;

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

reg [31:0] S_01_FP_in1, S_01_FP_in2;
reg [1:0] S_01_round_mode;
reg S_01_round_mode;
reg S_01_is_subnormal1, S_01_is_subnormal2;

always @ (posedge clk) begin
//stage 0
    S_01_is_subnormal1 <= is_subnormal1;
    S_01_is_subnormal2 <= is_subnormal2;
    S_01_FP_in1 <= FP_in1;
    S_01_FP_in2 <= FP_in2;
    S_01_round_mode <= round_mode;
    S_01_calc_mode <= calc_mode;

end
endmodule