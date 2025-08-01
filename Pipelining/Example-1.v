/*
Conside a pipeline that carries out the follwing stage-wise operations:
    1. Inputs: Three register addresses (rs1, rs2, rd), an ALU funtion (func) and a memory address (addr).
    2. Stage 1: read teo 16 bit numbers from the registers specified by 'rs1' and 'rs2' and store them in A and B.
    3. Stage 2: perform the alu operation on A and B specified by "func" and store it in Z.
    4. Stage 3: Write the value of Z in the register specified by "rd".
    5. Stage 4: Also write the value of Z in memory location "addr".
*/
module pipeline_example (
    input wire [3:0] rs1, rs2, rd, func,
    input wire [7:0] addr,
    input wire clk1, clk2,

    output wire [15:0] z_out
    
);
    //reg [3:0] rs1, rs2, rd, func;
    //reg [7:0] addr

    reg [15:0] L12_A, L12_B, L23_alu_out, L34_alu_out;            
    reg [7:0] L12_addr, L23_addr, L34_addr;
    reg [3:0] L12_rd, L23_rd, L12_func;

    reg [15:0] register_bank [0:16]; 
    reg [15:0] memory [0:256];

assign z_out = L34_alu_out;
 
always @(posedge clk1) begin
    /*stage 1*/
    L12_A <= register_bank[rs1];
    L12_rd <= rd;
    L12_B <= register_bank[rs2];
    L12_addr <= addr;
    L12_func <= func;
    /*stage 3*/
    L34_alu_out <= L23_alu_out;
    L34_addr <= L23_addr;
    register_bank[L23_rd] <= L23_alu_out;
end

always @(posedge clk2) begin
    /*stage 2*/
        L23_rd <= L12_rd;

    case (L12_func)
        4'b0010: L23_alu_out <= L12_A - L12_B;
        4'b0001: L23_alu_out <= L12_A + L12_B;
        4'b0011: L23_alu_out <= L12_A & L12_B;
        4'b0100: L23_alu_out <= L12_A | L12_B;
        4'b0101: L23_alu_out <= L12_A ^ L12_B;
        4'b0110: L23_alu_out <= ~L12_B;
        4'b0111: L23_alu_out <= ~L12_A;
        default: L23_alu_out <= 16'b0;
    endcase
    L23_addr <= L12_addr;

    /*stage 4*/
    memory[L34_addr] <= L34_alu_out;

end

endmodule