module RegisterUnit(data_out, data_in, load, clk, rst); 
    // data width
    parameter data_width = 16;

    // Input output declaration
    output [data_width-1:0] data_out;
    input [data_width-1:0] data_in;
    input load;
    input clk,rst;
    reg [data_width-1:0] data_out;

    always @(posedge clk or negedge rst) begin 
        if (rst==0) begin 
            data_out <= 0;
        end
        else if (load) begin 
            data_out <= data_in;
        end
    end
endmodule

// module RegisterFile (
//     input clk, rst,
//     input [3:0] Rp_addr, Rq_addr, W_addr,  // 4-bit address lines (16 registers)
//     input W_wr, Rp_rd, Rq_rd,              // Enable signals for write and read
//     input [15:0] W_data,                   // 16-bit write data
//     output reg [15:0] Rp_data, Rq_data     // 16-bit read data outputs
// );
//     parameter data_width = 16;
//     parameter num_registers = 16;

//     // Declare the 16 registers
//     reg [data_width-1:0] registers [0:num_registers-1];

//     integer i;

//     // Initialize the register file on reset
//     always @(posedge clk or negedge rst) begin
//         if (!rst) begin
//             for (i = 0; i < num_registers; i = i + 1) begin
//                 registers[i] <= 0;
//             end
//         end
//         else if (W_wr) begin
//             registers[W_addr] <= W_data;
//         end
//     end

//     // Read logic for Rp_data and Rq_data
//     always @(posedge clk) begin
//         if (Rp_rd) begin
//             Rp_data = registers[Rp_addr];
//         end 
//         // else begin
//         //     Rp_data = 0;
//         // end
        
//         if (Rq_rd) begin
//             Rq_data = registers[Rq_addr];
//         end 
//         // else begin
//         //     Rq_data = 0;
//         // end
//     end

// endmodule
