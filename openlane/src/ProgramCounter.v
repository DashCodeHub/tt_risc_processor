// Design a Program Counter for RISC Processor
module ProgramCounter(
    ctr, 
    up, 
    clr, 
    load, 
    clk, 
    data_in
);
    // Parameter data_width
    parameter data_width = 16;
    // Input and Output
    input [data_width-1:0] data_in;
    input clr; // reset PC
    input load; // Load PC
    input clk; 
    input up; // Increment PC
    output [data_width-1:0]  ctr;
    // Declare register
    reg [data_width-1:0] ctr;

    always @(posedge clk or negedge clr) begin 
        if (clr==0) begin 
            ctr <= 0;
        end
        else if (load) begin 
            ctr <= data_in;
        end
        else if (up) begin 
            ctr <= ctr + 1;
        end
    end
endmodule
