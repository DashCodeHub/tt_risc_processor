`include "alu.v"
`include "mux.v"
`include "InstructionRegister.v"
`include "ProgramCounter.v"
`include "compute_offset.v"
`include "AddressRegister.v"
`include "CheckZero.v"
`include "D_flop.v"
`include "RegisterFile.v"
`include "increment.v"
`include "decoder.v"
`include "sign_ext_immediate.v"

module ProcessingUnit(instruction, RF_Ry_Zero, alu_zero, Bus_1, address, mem_read_data, RF_W_Addr, PC_Ld, PC_Inc, sel_PC_Offset_Update, Sel_Bus_1_MUX, Sign_Ext_Flag, IR_Ld, Reg_Y_Ld, Sel_Bus_2_MUX, Reg_A_Ld, Reg_Z_Ld, clk, rst );

    // Define parameter
    parameter data_width = 16; // Width of all data
    parameter addr_width = 8; // Address width for memory and Program Counter
    parameter RF_W_Addr_Width = 4; //Register file address width
    parameter RF_Depth = 16; // Register File Depth


    parameter opcode_size = 4; // Opcode Size
    parameter sel_bus_1_size = 5; //select control width
    parameter sel_bus_2_size = 2; // select control width

    // Input and output declaration
    output [data_width-1:0] instruction; // instruction sent to contol unit to decode
    output [addr_width-1:0] address; // Output address for memory read
    output [data_width-1:0] Bus_1; // Bus 1
    output RF_Ry_Zero; // Zero Flag for Operand in Reg_Y
    output alu_zero; // Zero flag from ALU
    
    
    input [data_width-1:0] mem_read_data; // input data from the memory
    input [RF_W_Addr_Width-1:0] RF_W_Addr; // input Reg File Address Control Signal to read register file 
    input PC_Ld; // Load PC Control Signal *To be used while BIZ, BNZ, JAL, JMP ,JR to update PC with Offset
    input PC_Inc; // Incremenet PC Control Signal
    input sel_PC_Offset_Update; // Select between offset update (a+b-1) or data from BUS_2
    input [sel_bus_1_size-1:0] Sel_Bus_1_MUX; // Selct BUS_1 Control Signal
    input Sign_Ext_Flag; // Control signal to do sign extension immediate
    input IR_Ld; // Instruction Register Load control signal
    input Reg_Y_Ld; // Load Reg Y Control Signal
    input [sel_bus_2_size-1:0] Sel_Bus_2_MUX; // Select BUS_2 Control Signal
    input Reg_A_Ld; // Load Reg_A control Signal
    input Reg_Z_Ld; // Load Reg_Z control Signal
    input clk, rst; // CLOCK and RESET inputs

    // Temporary Intermediate wires
    wire [RF_Depth-1:0] load_BUS_to_RF; // Wire in between decoder and Register File
    wire [RF_Depth-1:0] R0_out, R1_out, R2_out, R3_out, R4_out, R5_out, R6_out, R7_out, R8_out, R9_out, R10_out, R11_out, R12_out, R13_out, R14_out, R15_out; // Ouptuts from Register File to 18x1 MUX [MUX1]
    wire [data_width-1:0] Bus_2; // Bus 2 for connection between hardwares inside the the processor unit
    wire [data_width-1:0] PC_addr; // Output from Program Counter
    wire [data_width-1:0] PC_data_in; // Input to Program Counter from 2x1 MUX3
    wire [data_width-1:0] Offset_PC_addr; // new PC address after calculation of PC_addr + IR[7:0](offset) - 1
    wire [data_width-1:0] Offset = {8'b0, instruction[7:0]} ; // Offset Output from IR
    wire [data_width-1:0] Imm_ext_data; // Signed Immediate data calculate
    wire [data_width-1:0] Reg_Y_Out; // Ouptut from Reg_Y to ALU
    wire [data_width-1:0] alu_out; // output from ALU
    wire [opcode_size-1:0] opcode = instruction[data_width-1:data_width-opcode_size]; // OPcode
    wire alu_zero_flag;
    

    // Connect a Register File Using Register File with decoder inbetween them 
    decoder_4_to_16 decode_RF_Address (
        .binary_in(RF_W_Addr),  // 4-bit binary input
        .dec_out(load_BUS_to_RF)    // 16-bit decoder output
    );
    // all registers in register file (16x16)
    RegisterUnit R0 (.data_out(R0_out), .data_in(Bus_2), .load(load_BUS_to_RF[0]), .clk(clk), .rst(rst));
    RegisterUnit R1 (.data_out(R1_out), .data_in(Bus_2), .load(load_BUS_to_RF[1]), .clk(clk), .rst(rst));
    RegisterUnit R2 (.data_out(R2_out), .data_in(Bus_2), .load(load_BUS_to_RF[2]), .clk(clk), .rst(rst));
    RegisterUnit R3 (.data_out(R3_out), .data_in(Bus_2), .load(load_BUS_to_RF[3]), .clk(clk), .rst(rst));
    RegisterUnit R4 (.data_out(R4_out), .data_in(Bus_2), .load(load_BUS_to_RF[4]), .clk(clk), .rst(rst));
    RegisterUnit R5 (.data_out(R5_out), .data_in(Bus_2), .load(load_BUS_to_RF[5]), .clk(clk), .rst(rst));
    RegisterUnit R6 (.data_out(R6_out), .data_in(Bus_2), .load(load_BUS_to_RF[6]), .clk(clk), .rst(rst));
    RegisterUnit R7 (.data_out(R7_out), .data_in(Bus_2), .load(load_BUS_to_RF[7]), .clk(clk), .rst(rst));
    RegisterUnit R8 (.data_out(R8_out), .data_in(Bus_2), .load(load_BUS_to_RF[8]), .clk(clk), .rst(rst));
    RegisterUnit R9 (.data_out(R9_out), .data_in(Bus_2), .load(load_BUS_to_RF[9]), .clk(clk), .rst(rst));
    RegisterUnit R10 (.data_out(R10_out), .data_in(Bus_2), .load(load_BUS_to_RF[10]), .clk(clk), .rst(rst));
    RegisterUnit R11 (.data_out(R11_out), .data_in(Bus_2), .load(load_BUS_to_RF[11]), .clk(clk), .rst(rst));
    RegisterUnit R12 (.data_out(R12_out), .data_in(Bus_2), .load(load_BUS_to_RF[12]), .clk(clk), .rst(rst));
    RegisterUnit R13 (.data_out(R13_out), .data_in(Bus_2), .load(load_BUS_to_RF[13]), .clk(clk), .rst(rst));
    RegisterUnit R14 (.data_out(R14_out), .data_in(Bus_2), .load(load_BUS_to_RF[14]), .clk(clk), .rst(rst));
    RegisterUnit R15 (.data_out(R15_out), .data_in(Bus_2), .load(load_BUS_to_RF[15]), .clk(clk), .rst(rst));

    // Instantiate The PC
    ProgramCounter PC(
        .ctr(PC_addr), 
        .up(PC_Inc), 
        .clr(rst), 
        .load(PC_Ld), 
        .clk(clk), 
        .data_in(PC_data_in)
    );
    // MUX for PC load data select
    MUX2x1 LoadPC_Data(
        .s(sel_PC_Offset_Update),
        .data_0(Offset_PC_addr),
        .data_1(Bus_2),
        .data_out(PC_data_in)
    );
    // Offset calculation
    compute_offset PC_Offset(
        .A(PC_addr), // PC Address
        .B(Offset), // Offset from IR[7:0] given as {8'b0, instruction[7:0]}
        .new_A(Offset_PC_addr) // new PC address to update 
    );
    //Instruction Register
    InstructionRegister IR(
        .instr_in(Bus_2), // Input of instruction through Bus_2, Given Wrong in book
        .IR_ld(IR_Ld), 
        .instr_out(instruction), 
        .clk(clk), 
        .rst(rst)
    );
    //Sign Extension
    sign_extend_immediate sign_ext(
        .in(instruction[7:0]),        // 8-bit input number
        .sign_extend_en(Sign_Ext_Flag),  // Control signal for enabling sign extension
        .out(Imm_ext_data)       // 16-bit output number
    );
    //Connect the RegisterFile Outputs, PC and IR to MUX1(18x1) with control signal `Sel_Bus_1_MUX`->5bits
    MUX18x1 MUX1(
        .s(Sel_Bus_1_MUX),
        .data_0(R0_out), 
        .data_1(R1_out), 
        .data_2(R2_out), 
        .data_3(R3_out), 
        .data_4(R4_out), 
        .data_5(R5_out), 
        .data_6(R6_out), 
        .data_7(R7_out), 
        .data_8(R8_out), 
        .data_9(R9_out), 
        .data_10(R10_out), 
        .data_11(R11_out), 
        .data_12(R12_out), 
        .data_13(R13_out), 
        .data_14(R14_out), 
        .data_15(R15_out), 
        .data_16(PC_addr), //OUTPUT FROM PC
        .data_17(Imm_ext_data), //Output from Sign Extended from Instruction Register
        .data_out(Bus_1) // Output to Bus_1
    ); 
    // Add RegY
    RegisterUnit Reg_Y (.data_out(Reg_Y_Out), .data_in(Bus_2), .load(Reg_Y_Ld), .clk(clk), .rst(rst));
    // Check if Reg_Y output is zero
    CheckZero Check_Zero_for_RegY(
        .Rp_data(Reg_Y_Out), // Input to Check Zero module from Reg_Y
        .Rp_zero(RF_Ry_Zero) // output to controller module
    );

    // Check ALU Zero FLAG
    D_flop Reg_Z(.data_out(alu_zero), .data_in(alu_zero_flag), .load(Reg_Z_Ld), .clk(clk), .rst(rst));
    // add ALU
    alu ALU_RISC(
        .alu_A(Reg_Y_Out), // One input to ALU from Reg_Y
        .alu_B(Bus_1), // One input to ALU from BUS
        .alu_OUT(alu_out), // Output from ALU
        .opcode(opcode), // Opcode to selet operation
        .alu_zero_flag(alu_zero_flag)
    ); 

    // Add Address Register
    AddressRegister Reg_A (.data_out(address), .data_in(Bus_2[7:0]), .load(Reg_A_Ld), .clk(clk), .rst(rst));
    
    // MUX 3X1 to select from  alu_output, bus_1, read_Data(from memory) 
    MUX3x1 MUX2(
        .s(Sel_Bus_2_MUX),
        .data_0(alu_out),
        .data_1(Bus_1),
        .data_2(mem_read_data),
        .data_out(Bus_2)
    );
    
endmodule
