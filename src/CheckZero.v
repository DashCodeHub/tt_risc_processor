// Check if Register Rp is equal to zero

module CheckZero(
    Rp_data,
    Rp_zero
);
    // data_width
    parameter data_width = 16;
    //input output data declaration
    input [data_width-1:0] Rp_data;
    output Rp_zero;
    //Assign `alu_zero_flag` if alu_OUT is 0
    assign Rp_zero = ~|Rp_data;
endmodule
