module D_flop(data_out, data_in, load, clk, rst);
    output data_out;
    input data_in;
    input load;
    input clk, rst;
    reg data_out;

    always @(posedge clk or negedge rst) begin 
        if (rst==0) begin 
            data_out <= 0;
        end
        else if (load==1) begin 
            data_out <= data_in;
        end
    end
endmodule
