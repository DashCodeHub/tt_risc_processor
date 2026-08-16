// Designing the main memory for RISC PRocessor
// Size of the memory 256x16 i.e. 256 locations, from 0x00/00000000 to 0xFF/11111111
// Each location 16 bit

module main_memory(
    W_data,
    R_data,
    wr,
    addr,
    clk
); 
    
    parameter depth = 256; // Depth of the memory
    parameter addr_width = 8; // Address width
    parameter data_width = 16; // Parameter widht of the data

    // input and output declaration
    input [data_width-1:0] W_data; // data_in
    input [addr_width-1:0] addr; // address
    input wr; // write
    input clk;
    output [data_width-1:0] R_data; // data out

    // Wire reg declaration 
    //reg [data_width-1:0] R_data;
    //reg [data_width-1:0] W_data;
    
    // Declare memory reggister
    reg [data_width-1:0] memory256x16 [depth-1:0];

    // insert the instruction and data to the memory
    initial begin 
        memory256x16[0] = 16'b1001_0101_1100_1001; // LW 5 201
        memory256x16[1] = 16'b1001_0110_1100_1010; // LW 6 202
        memory256x16[2] = 16'b0000_0111_0101_0110; // ADD 7 5 6
        memory256x16[3] = 16'b1010_0111_1100_1011; // SW 7 203
        memory256x16[4] = 16'b1000_1000_1111_1010; // LI 8 250
        memory256x16[5] = 16'b0001_0100_1000_0101; // SUB 4 8 5
        memory256x16[6] = 16'b1010_0100_1100_1100; //SW 4 204
        memory256x16[7] = 16'b0111_0011_0111_0000; // SRA 3 7
        memory256x16[8] = 16'b0100_0010_0011_0100; // XOR 2 3 4
        memory256x16[9] = 16'b1010_0010_1100_1101; // SW 2 205
        memory256x16[201] = 16'h1111; // Initial value for location 201
        memory256x16[202] = 16'h2222; // Initial value for location 202
    end

    
    assign R_data = memory256x16[addr];
    //Writing data
    always @(posedge clk) begin
        if (wr) begin 
            memory256x16[addr] <= W_data;
        end
    end


endmodule
