// Instruction Register for RISC Processor

module InstructionRegister(
    instr_in, 
    IR_ld, 
    instr_out, 
    clk, 
    rst
    );
    // instruction width parameter
    parameter instruction_width = 16;

    // Input output declaration 
    input [instruction_width-1:0] instr_in;
    input IR_ld;
    input clk;
    input rst;
    output reg [instruction_width-1:0] instr_out;

    // logic
    always @(posedge clk or negedge rst) begin 
        if (rst==0) begin 
            instr_out <= 0;
        end
        else if (IR_ld) begin 
            instr_out <= instr_in;
        end
    end

endmodule
