module prenormalization(
    input wire [31:0] FP_in1, FP_in2,
    input wire calc_mode,
    input wire clk,
    input wire [1:0] subnormal_status,

    output reg [31:0] FP_result
);
reg [22:0] shifted_mantissa1, shifted_mantissa2;
wire compare_exponents; // 1 if FP_in1 has a smaller exponent, 0 if FP_in2 has a smaller exponent
assign compare_exponents = (FP_in1[30:23] < FP_in2[30:23]) ? 1'b1 : 1'b0;
always @(posedge clk) begin
    case(subnormal_status)
        2'b00: begin    //both inputs are normal
            if(compare_exponents) begin
                shifted_mantissa1 <= (FP_in1[30:23] >> (FP_in1[30:23] - FP_in2[30:23]));
                shifted_mantissa2 <= FP_in2[30:23]
            end else begin
                shifted_mantissa2 <= (FP_in2[30:23] >> (FP_in2[30:23] - FP_in1[30:23]));
                shifted_mantissa1 <= FP_in1[30:23];
            end
        end
        2'b01, 2'b10, 2'b11: begin    // one input or both input are subnormal
            shifted_mantissa1 <= FP_in1[22:0];
            shifted_mantissa2 <= FP_in2[22:0];
        end
        default: begin
            shifted_mantissa1 <= 23'b0;
            shifted_mantissa2 <= 23'b0;
        end
    endcase
end
endmodule