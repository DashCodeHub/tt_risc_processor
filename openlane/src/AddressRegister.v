module AddressRegister(
    data_out, 
    data_in, 
    load, 
    clk, 
    rst
    );
    //address width  
    parameter addr_width = 8;
    output [addr_width-1:0] data_out;
    input [addr_width-1:0] data_in;
    input load, clk, rst;
    reg [addr_width-1:0] data_out;

    always @(posedge clk or negedge rst) begin 
        if (rst==0) begin 
            data_out <= 0;
        end
        else if (load) begin 
            data_out <= data_in;
        end
    end
endmodule
