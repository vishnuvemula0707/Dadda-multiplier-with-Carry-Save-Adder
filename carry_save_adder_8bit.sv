module carry_save_adder_8bit(
    input  wire [7:0] A,
    input  wire [7:0] B,
    input  wire [7:0] C,
    output wire [7:0] Sum,
    output wire [7:0] Cout
);
    full_adder fa0 (A[0], B[0], C[0], Sum[0], Cout[0]);
    full_adder fa1 (A[1], B[1], C[1], Sum[1], Cout[1]);
    full_adder fa2 (A[2], B[2], C[2], Sum[2], Cout[2]);
    full_adder fa3 (A[3], B[3], C[3], Sum[3], Cout[3]);
    full_adder fa4 (A[4], B[4], C[4], Sum[4], Cout[4]);
    full_adder fa5 (A[5], B[5], C[5], Sum[5], Cout[5]);
    full_adder fa6 (A[6], B[6], C[6], Sum[6], Cout[6]);
    full_adder fa7 (A[7], B[7], C[7], Sum[7], Cout[7]);
endmodule

