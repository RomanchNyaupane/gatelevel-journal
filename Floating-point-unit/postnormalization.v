module postnormalization(
    input wire result_sign,
    input wire extra_exponent,
    input wire [7:0] main_exponent,
    input wire first_exponent,
    input wire [22:0] FP_result,
    input wire [1:0] round_mode,
    input wire clk,

    output reg [31:0] FP_out
);
    reg [22:0] S_34_FP_result;
    reg S_34_first_exponent;
    reg S_34_result_sign;
    reg S_34_extra_exponent;
    reg [7:0] S_34_main_exponent;

    reg [2:0] res;

    wire [4:0] shift_amt;
    wire [22:0] FP_result_shifted;

    assign shift_amt = 
    (S_34_first_exponent) ? 5'd0 :
    (S_34_FP_result[22]) ? 5'd1 :
    (S_34_FP_result[21]) ? 5'd2 :
    (S_34_FP_result[20]) ? 5'd3 :
    (S_34_FP_result[19]) ? 5'd4 :
    (S_34_FP_result[18]) ? 5'd5 :
    (S_34_FP_result[17]) ? 5'd6 :
    (S_34_FP_result[16]) ? 5'd7 :
    (S_34_FP_result[15]) ? 5'd8 :
    (S_34_FP_result[14]) ? 5'd9 :
    (S_34_FP_result[13]) ? 5'd10 :
    (S_34_FP_result[12]) ? 5'd11 :
    (S_34_FP_result[11]) ? 5'd12 :
    (S_34_FP_result[10]) ? 5'd13 :
    (S_34_FP_result[9])  ? 5'd14 :
    (S_34_FP_result[8])  ? 5'd15 :
    (S_34_FP_result[7])  ? 5'd16 :
    (S_34_FP_result[6])  ? 5'd17 :
    (S_34_FP_result[5])  ? 5'd18 :
    (S_34_FP_result[4])  ? 5'd19 :
    (S_34_FP_result[3])  ? 5'd20 :
    (S_34_FP_result[2])  ? 5'd21 :
    (S_34_FP_result[1])  ? 5'd22 :
    (S_34_FP_result[0])  ? 5'd23 :
    5'd0;

assign FP_result_shifted = (shift_amt == 24) ? 23'b0 : (S_34_FP_result << shift_amt);

always @(posedge clk) begin
    S_34_first_exponent <= first_exponent;
    S_34_result_sign <= result_sign;
    S_34_main_exponent <= main_exponent;
    S_34_extra_exponent <= extra_exponent;
    case (round_mode)
        2'b00: begin //round to nearest even
            if (FP_result[0]) begin
                S_34_FP_result <= FP_result + 1'b1; //add 1 if the 25th bit is set
            end else begin
                S_34_FP_result <= FP_result; //no change if the 25th bit is not set
            end
        end
        2'b01: begin //round towards zero
            S_34_FP_result <= {FP_result, 1'b0}; //truncate the last bit
        end
        2'b10: begin //round towards positive infinity
            if (result_sign) begin //if the result is negative, do not round up
                S_34_FP_result <= FP_result; //no change if negative
            end else begin
                S_34_FP_result <= FP_result + 1; //round up if positive
            end
        end
        2'b11: begin //round towards negative infinity
            if (result_sign) begin //if the result is negative, round down
                S_34_FP_result <= FP_result - 1; //round down if negative
            end else begin
                S_34_FP_result <= FP_result; //no change if positive
            end
        end
        default: begin
            S_34_FP_result <= FP_result;
        end
    endcase
    if (S_34_extra_exponent) begin
        if(((S_34_main_exponent == 1'b0)&&(S_34_FP_result == 22'b0))) begin FP_out <= 32'b0; res <= 3'b000; end
        else if(S_34_extra_exponent && S_34_result_sign) begin FP_out <= {S_34_result_sign, (S_34_main_exponent), S_34_FP_result[22:0]}; res <= 3'b001; end
        else begin FP_out <= {S_34_result_sign, (S_34_main_exponent + 8'b1), {S_34_first_exponent, S_34_FP_result[22:1]}}; res <= 3'b010; end
    end else begin
         if(S_34_first_exponent) begin
             FP_out <= {S_34_result_sign, S_34_main_exponent, S_34_FP_result[22:0]};
             res <= 3'b100;
         end else if (!((S_34_FP_result))) begin
             FP_out <= 32'b0;
             res <= 3'b101;
         end else begin FP_out <= {S_34_result_sign,(S_34_main_exponent - shift_amt) ,FP_result_shifted}; res <= 3'b110; end
    end
end
endmodule