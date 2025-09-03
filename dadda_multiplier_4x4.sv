module dadda_multiplier_4x4(
    input  wire [3:0] A,
    input  wire [3:0] B,
    output wire [7:0] P
);
    // 1) Partial products (aligned into 8 bits)
    wire [7:0] pp0 = {4'b0,           A & {4{B[0]}}        }; // weight 0-3
    wire [7:0] pp1 = {3'b0,           A & {4{B[1]}}, 1'b0}; // weight 1-4
    wire [7:0] pp2 = {2'b0,           A & {4{B[2]}}, 2'b0}; // weight 2-5
    wire [7:0] pp3 = {1'b0,           A & {4{B[3]}}, 3'b0}; // weight 3-6

    // 2) Level-1 CSA: pp0 + pp1 + pp2 → s1, c1
    wire [7:0] s1, c1;
    carry_save_adder_8bit csa1 (
      .A   (pp0),
      .B   (pp1),
      .C   (pp2),
      .Sum (s1),
      .Cout(c1)
    );
    wire [7:0] c1_sh = c1 << 1; // carry bits shifted into next weight

    // 3) Level-2 CSA: s1 + c1_sh + pp3 → s2, c2
    wire [7:0] s2, c2;
    carry_save_adder_8bit csa2 (
      .A   (s1),
      .B   (c1_sh),
      .C   (pp3),
      .Sum (s2),
      .Cout(c2)
    );
    wire [7:0] c2_sh = c2 << 1;

    // 4) Final ripple-carry add: s2 + c2_sh
    wire [7:0] final_sum;
    wire       final_cout;
    ripple_carry_adder_8bit rca (
      .A   (s2),
      .B   (c2_sh),
      .Cin (1'b0),
      .Sum (final_sum),
      .Cout(final_cout)
    );

    assign P = final_sum;
endmodule

