module dadda_multiplier_with_io_ff (
    input  wire        clk,
    input  wire        reset,
    input  wire [3:0]  A_in,
    input  wire [3:0]  B_in,
  output wire [7:0]  P_reg_out
);

    // Input flip-flops
    reg [3:0] A_reg, B_reg;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            A_reg <= 4'b0;
            B_reg <= 4'b0;
        end else begin
            A_reg <= A_in;
            B_reg <= B_in;
        end
    end

    // Internal wire for combinational result
    wire [7:0] P_comb;

    // Dadda multiplier instance
    dadda_multiplier_4x4 mult_inst (
        .A(A_reg),
        .B(B_reg),
        .P(P_comb)
    );

    // Output flip-flops
    reg [7:0] P_reg;
    always @(posedge clk or posedge reset) begin
        if (reset)
            P_reg <= 8'b0;
        else
            P_reg <= P_comb;
    end

    // Final registered output
    assign P_reg_out = P_reg;

endmodule
