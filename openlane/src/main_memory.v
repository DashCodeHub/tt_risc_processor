// Designing the main memory for RISC PRocessor
// PHASE 2 (BUG-02): resized 256x16 -> 32x16 and removed `initial` preload.
//  - 256x16 = 4,096 flip-flops in sky130 (no inferred SRAM in the TT digital flow),
//    ~16 tiles of area for memory alone. 32x16 = 512 flops fits the 2x2-tile budget.
//  - `initial` blocks only exist in simulation/FPGA bitstreams; on an ASIC this memory
//    powers up as garbage. The program is now streamed in by the RP2040 through loader.v.

module main_memory(
    W_data,
    R_data,
    wr,
    addr,
    clk
); 
    
    // FIX (BUG-02): OLD: parameter depth = 256;  OLD: parameter addr_width = 8;
    parameter depth = 32; // Depth of the memory (parameterized: bump to 64 post-hardening if area allows)
    parameter addr_width = 5; // Address width
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

    // FIX (BUG-02): initial-block program load removed - does not exist on silicon.
    // Program is written through the same write port by loader.v before the CPU runs.
    // OLD: // insert the instruction and data to the memory
    // OLD: initial begin
    // OLD: memory256x16[0] = 16'b1001_0101_1100_1001; // LW 5 201
    // OLD: memory256x16[1] = 16'b1001_0110_1100_1010; // LW 6 202
    // OLD: memory256x16[2] = 16'b0000_0111_0101_0110; // ADD 7 5 6
    // OLD: memory256x16[3] = 16'b1010_0111_1100_1011; // SW 7 203
    // OLD: memory256x16[4] = 16'b1000_1000_1111_1010; // LI 8 250
    // OLD: memory256x16[5] = 16'b0001_0100_1000_0101; // SUB 4 8 5
    // OLD: memory256x16[6] = 16'b1010_0100_1100_1100; //SW 4 204
    // OLD: memory256x16[7] = 16'b0111_0011_0111_0000; // SRA 3 7
    // OLD: memory256x16[8] = 16'b0100_0010_0011_0100; // XOR 2 3 4
    // OLD: memory256x16[9] = 16'b1010_0010_1100_1101; // SW 2 205
    // OLD: memory256x16[201] = 16'h1111; // Initial value for location 201
    // OLD: memory256x16[202] = 16'h2222; // Initial value for location 202
    // OLD: end

    
    assign R_data = memory256x16[addr];
    //Writing data
    always @(posedge clk) begin
        if (wr) begin 
            memory256x16[addr] <= W_data;
        end
    end


endmodule