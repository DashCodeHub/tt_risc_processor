module sign_extend_immediate (
    input wire [7:0] in,        // 8-bit input number
    input wire sign_extend_en,  // Control signal for enabling sign extension
    output reg [15:0] out       // 16-bit output number
);

    always @(*) begin
        if (sign_extend_en) begin
            // If sign_extend_en is high, perform sign extension
            out = {{8{in[7]}}, in};  // Replicate the sign bit (in[7]) and concatenate with the input
        end else begin
            // If sign_extend_en is low, zero-extend the input
            out = {8'b0, in};  // Concatenate 8 zeros with the input
        end
    end

endmodule
