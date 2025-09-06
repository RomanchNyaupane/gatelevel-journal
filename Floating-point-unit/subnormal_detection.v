module subnormal_detection(
    input wire [31:0] FP_in,
    output reg is_subnormal,
    input wire clk
);
always @(*) begin
    is_subnormal <= & (~(FP_in[30:23]));
end

endmodule