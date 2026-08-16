module decoder_4_to_16 (
    input wire [3:0] binary_in,  // 4-bit binary input
    output reg [15:0] dec_out    // 16-bit decoder output
);

    // Always block to implement combinational logic
    always @(*) begin
        // Initialize output to all zeros
        dec_out = 16'b0;
        
        // Set the appropriate output bit based on the input
        case (binary_in)
            4'b0000: dec_out[0] = 1'b1;
            4'b0001: dec_out[1] = 1'b1;
            4'b0010: dec_out[2] = 1'b1;
            4'b0011: dec_out[3] = 1'b1;
            4'b0100: dec_out[4] = 1'b1;
            4'b0101: dec_out[5] = 1'b1;
            4'b0110: dec_out[6] = 1'b1;
            4'b0111: dec_out[7] = 1'b1;
            4'b1000: dec_out[8] = 1'b1;
            4'b1001: dec_out[9] = 1'b1;
            4'b1010: dec_out[10] = 1'b1;
            4'b1011: dec_out[11] = 1'b1;
            4'b1100: dec_out[12] = 1'b1;
            4'b1101: dec_out[13] = 1'b1;
            4'b1110: dec_out[14] = 1'b1;
            4'b1111: dec_out[15] = 1'b1;
            default: dec_out = 16'b0;  // Default case for safety
        endcase
    end
endmodule
