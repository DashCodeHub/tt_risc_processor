// Use new control Unit (COntrolUnit2)
`include "ProcessingUnit.v"
`include "ControlUnit2.v"
`include "main_memory.v"

module risc_machine (clk, rst);
    // parameters description
    parameter data_width = 16; // Width of all data
    parameter addr_width = 8; // Address width for memory and Program Counter
    parameter RF_W_Addr_Width = 4; //Register file address width
    parameter RF_Depth = 16; // Register File Depth


    parameter opcode_size = 4; // Opcode Size
    parameter sel_bus_1_size = 5; //select control width
    parameter sel_bus_2_size = 2; // select control width

    //input output declaration
    input clk, rst;

    // Selects for Buses
    wire [sel_bus_1_size-1:0] Sel_Bus_1_MUX; // Selct BUS_1 Control Signal
    wire [sel_bus_2_size-1:0] Sel_Bus_2_MUX; // Select BUS_2 Control Signal
    
    // Data Nets
    wire alu_zero;
    wire RF_Ry_Zero;
    wire [data_width-1:0] instruction;
    wire [addr_width-1:0] address;
    wire [data_width-1:0] Bus_1;
    wire [data_width-1:0] mem_read_data; // input data from the memory

    // Control Nets
    wire PC_Ld; 
    wire PC_Inc; 
    wire sel_PC_Offset_Update; 
    wire Sign_Ext_Flag; 
    wire IR_Ld; 
    wire Reg_Y_Ld; 
    wire Reg_A_Ld; 
    wire Reg_Z_Ld; 
    wire [RF_W_Addr_Width-1:0] RF_W_Addr;
    wire D_wr; // data write enable signal

    //ProcessingUnit
    ProcessingUnit PU (instruction, RF_Ry_Zero, alu_zero, Bus_1, address, mem_read_data, RF_W_Addr, PC_Ld, PC_Inc, sel_PC_Offset_Update, Sel_Bus_1_MUX, Sign_Ext_Flag, IR_Ld, Reg_Y_Ld, Sel_Bus_2_MUX, Reg_A_Ld, Reg_Z_Ld, clk, rst);

    // Control Unit
    ControlUnit2 CU(
        PC_Ld, PC_Inc, sel_PC_Offset_Update, // Control Signals for PC
        RF_W_Addr,  // Address to write into Register File
        IR_Ld, // Control Signals to Load Instruction Register
        Sign_Ext_Flag, // Control Signal for Sign Extension immediate
        Sel_Bus_1_MUX, // Control Bus_1 MUX1
        Reg_Y_Ld, // Control Signal for Reg_Y
        RF_Ry_Zero, //Output Flag to check operand in RegY is 0 or not
        instruction, //Output instrution bytes
        Sel_Bus_2_MUX, // Control Bus_2 MUX2
        Reg_A_Ld, // Control Signal to Load Reg_A (Address_Register)
        Reg_Z_Ld, // Control Signal to Load Reg_Z (Zero ALU Flag)
        alu_zero, //Output flag for alu_output is 0 or not
        D_wr, // Data Write Enable signal to read memory
        clk, rst);

    // Memory Unit 
    main_memory MU(
        .W_data(Bus_1),
        .R_data(mem_read_data),
        .wr(D_wr),
        .addr(address),
        .clk(clk)
    );
    
endmodule
