module increment(
    inp, 
    out
);
    // address widht
    parameter addr_width = 8;

    //input output declaration 
    input [addr_width-1:0] inp;
    output [addr_width-1:0] out;

    // Logic 
    assign out = inp + 1;
    
endmodule
