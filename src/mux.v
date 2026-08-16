// In the RISC Architecture we need 2 MUX
// One 8 bit 2x1 MUX
// One 16 bit 3x1 MUX

//Make Two MUX with bit_width as parameter

//16-bit 3x1 MUX
module MUX3x1(
    s,
    data_0,
    data_1,
    data_2,
    data_out
);
    parameter data_width = 16;
    parameter sel_width = 2;
    //input output declaration
    input [sel_width-1:0] s;
    input [data_width-1:0] data_0, data_1, data_2;
    output [data_width-1:0] data_out;

    //logic for 3x1 MUX
    assign data_out = (s==0)? data_0: (s==1)? data_1: (s==2)? data_2: 16'bx; 

endmodule

//16-bit 2x1 MUX
module MUX2x1(
    s,
    data_0,
    data_1,
    data_out
); 
    parameter data_width = 16;
    //input output declaration
    input s;
    input [data_width-1:0] data_0, data_1;
    output [data_width-1:0] data_out;

    // logic 2x1 MUX
    assign data_out = s ? data_0: data_1;        
endmodule

//16-bit 18x1 MUX
module MUX18x1(
    s,
    data_0, data_1, data_2, data_3, data_4, data_5, data_6, data_7, data_8, data_9, data_10, data_11, data_12, data_13, data_14, data_15, data_16, data_17,
    data_out
); 
    parameter data_width = 16;
    parameter sel_width = 5;
    //input output declaration
    input [sel_width-1:0] s;
    input [data_width-1:0] data_0, data_1, data_2, data_3, data_4, data_5, data_6, data_7, data_8, data_9, data_10, data_11, data_12, data_13, data_14, data_15, data_16, data_17;
    output [data_width-1:0] data_out;

    // logic 2x1 MUX
    assign data_out = (s==0)? data_0: (s==1)? data_1: (s==2)? data_2:(s==3)? data_3: (s==4)? data_4: (s==5)? data_5: (s==6)? data_6: (s==7)? data_7: (s==8)? data_8: (s==9)? data_9: (s==10)? data_10: (s==11)? data_11: (s==12)? data_12:  (s==13)? data_13:  (s==14)? data_14: (s==15)? data_15: (s==16)? data_16: (s==17)? data_17: 16'bx;      
endmodule
