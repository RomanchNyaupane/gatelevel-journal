module prenormalization(
    input wire [31:0] FP_in1, FP_in2,
    input wire calc_mode,
    input wire clk,
    input wire [1:0] subnormal_status,

    output reg [23:0] FP_norm1, FP_norm2,
    output reg [7:0] main_exponent
);
    wire compare_exponents = (FP_in1[30:23] < FP_in2[30:23])? 1'b1 : 1'b0;
    wire [7:0] exp_diff = compare_exponents? (FP_in2[30:23] - FP_in1[30:23]) : (FP_in1[30:23] - FP_in2[30:23]);
    wire [1:0] zero_status = (!(|FP_in1[30:0]) && !(|FP_in2[30:0])) ? 2'b00 : //both zero
                                 !(|FP_in1[30:0]) ? 2'b01 : //FP_in1 zero
                                 !(|FP_in2[30:0]) ? 2'b10 : //FP_in2 zero
                                 2'b11;// both non-zero

    always @(posedge clk) begin        
        case(zero_status)
            2'b00: begin 
                FP_norm1 <= 24'b0;
                FP_norm2 <= 24'b0;
                main_exponent <= 8'b0;
            end
            2'b01: begin
                FP_norm1 <= 24'b0;
                FP_norm2 <= {1'b1, FP_in2[22:0]};
                main_exponent <= FP_in2[30:23];
            end
            2'b10: begin
                FP_norm1 <= {1'b1, FP_in1[22:0]};
                FP_norm2 <= 24'b0;
                main_exponent <= FP_in1[30:23];
            end
            2'b11: begin
                case(subnormal_status)
                    2'b00: begin 
                        if(compare_exponents) begin
                            FP_norm1 <= ({1'b1,FP_in1[22:0]} >> exp_diff);
                            FP_norm2 <= {1'b1, FP_in2[22:0]};
                            main_exponent <= FP_in2[30:23];
                        end else begin
                            FP_norm2 <= ({1'b1,FP_in2[22:0]} >> exp_diff);
                            FP_norm1 <= {1'b1, FP_in1[22:0]};
                            main_exponent <= FP_in1[30:23];
                        end
                    end
                    2'b01: begin //only FP_in1 is subnormal
                        FP_norm1 <= {1'b0, FP_in1[22:0]};
                        FP_norm2 <= {1'b1, FP_in2[22:0]} >> exp_diff;
                        main_exponent <= FP_in2[30:23];
                    end
                    2'b10: begin //only FP_in2 is subnormal
                        FP_norm1 <= {1'b1, FP_in1[22:0]} >> exp_diff;
                        FP_norm2 <= {1'b0, FP_in2[22:0]};
                        main_exponent <= FP_in1[30:23];
                    end
                    2'b11: begin //both inputs are subnormal
                        FP_norm1 <= {1'b0, FP_in1[22:0]};
                        FP_norm2 <= {1'b0, FP_in2[22:0]};
                        main_exponent <= 8'b0;
                    end
                endcase
            end
        endcase
    end
endmodule