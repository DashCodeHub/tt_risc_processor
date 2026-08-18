// Compute PC ctr given A = current address, B = Offset

module compute_offset(
    A, // PC Address
    B, // Offset
    new_A
);
    // Parameter
    parameter data_width = 16;

    input [data_width-1:0] A;
    input [data_width-1:0] B;
    output [data_width-1:0] new_A;

    // Logic
    assign new_A = A + B - 1;

endmodule
