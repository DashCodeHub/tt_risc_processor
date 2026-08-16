//CHNAGES

/*
Merge states into one state

S_ex1 = S_dec_source2 + S_ex1
*/

module ControlUnit2(
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

    // Parameter declaration
    parameter data_width = 16; // Width of the data
    parameter addr_width = 8; // Address width for memory and Program Counter
    parameter RF_W_Addr_Width = 4; //Register file address width
    // Instruction Format
    // instruction = xxxx_xxxx_xxxx_xxxx / opcode destination src1 src2
    // Opcode = instruction[15:12], Destination = instruction[11:8], Source = instruction[7:0]/ src1 = instruction[7:4] and src2 = instruction[3:0]
    parameter opcode_size  = 4; // Size of the opcode
    parameter state_size = 4; // 2^4 states
    parameter source_size = 8; // Last 8 bits are either address source or src1 + src2
    parameter src1_size = 4;
    parameter src2_size = 4;
    parameter dest_size = 4;
    // Select buses widths
    parameter sel_bus_1_size = 5; //select control width
    parameter sel_bus_2_size = 2; // select control width
    
    // States definition 
    parameter S_idle = 0;
    parameter S_fet1 = 1;
    parameter S_fet2 = 2;
    parameter S_dec_source_1 = 3;
    parameter S_dec_source_2 = 4;
    parameter S_ex1 = 5;
    parameter S_rd1 = 6;
    parameter S_rd2 = 7;
    parameter S_wr1 = 8;
    parameter S_wr2 = 9;
    /*Need to add some more states for BIZ, BNZ, JAL, JR, JMP*/
    parameter S_halt = 10;

    //OPCODE Definition
    parameter ADD = 4'b0000; 
    parameter SUB = 4'b0001; 
    parameter AND = 4'b0010; 
    parameter OR = 4'b0011; 
    parameter XOR = 4'b0100; 
    parameter NOT = 4'b0101; 
    parameter SLA = 4'b0110; 
    parameter SRA = 4'b0111; 
    parameter LI = 4'b1000; 
    parameter LW = 4'b1001;
    parameter SW = 4'b1010; 
    parameter BIZ = 4'b1011;
    parameter BNZ = 4'b1100; 
    parameter JAL = 4'b1101;
    parameter JMP = 4'b1110; 
    parameter JR = 4'b1111; 
    parameter NO_INSTR = 4'bx;

    // Source and Destination Codes
    parameter R0 = 4'd0;
    parameter R1 = 4'd1;
    parameter R2 = 4'd2;
    parameter R3 = 4'd3;
    parameter R4 = 4'd4;
    parameter R5 = 4'd5;
    parameter R6 = 4'd6;
    parameter R7 = 4'd7;
    parameter R8 = 4'd8;
    parameter R9 = 4'd9;
    parameter R10 = 4'd10;
    parameter R11 = 4'd11;
    parameter R12 = 4'd12;
    parameter R13 = 4'd13;
    parameter R14 = 4'd14;
    parameter R15 = 4'd15;
    parameter RYis0 = 0;
    parameter RYis1 = 1;

    // Input output declaration 
    output PC_Ld;
    output PC_Inc;
    output sel_PC_Offset_Update;
    output [RF_W_Addr_Width-1:0] RF_W_Addr;
    output IR_Ld;
    output Sign_Ext_Flag;
    output [sel_bus_1_size-1:0] Sel_Bus_1_MUX;
    output Reg_Y_Ld;
    output [sel_bus_2_size-1:0] Sel_Bus_2_MUX;
    output Reg_A_Ld;
    output Reg_Z_Ld;
    output D_wr;

    input RF_Ry_Zero;
    input [data_width-1:0] instruction;
    input alu_zero;
    input clk, rst;

    // Reg declaration 
    reg PC_Ld;
    reg PC_Inc;
    reg sel_PC_Offset_Update;
    reg [RF_W_Addr_Width-1:0] RF_W_Addr;
    reg IR_Ld;
    reg Sign_Ext_Flag;
    //reg [sel_bus_1_size-1:0] Sel_Bus_1_MUX;
    reg Reg_Y_Ld;
    //reg [sel_bus_2_size-1:0] Sel_Bus_2_MUX;
    reg Reg_A_Ld;
    reg Reg_Z_Ld;
    reg D_wr;



    // Internal Reg declaration
    // Select Registers for controlling the BUSES
    reg Sel_R0;
    reg Sel_R1;
    reg Sel_R2;
    reg Sel_R3;
    reg Sel_R4;
    reg Sel_R5;
    reg Sel_R6;
    reg Sel_R7;
    reg Sel_R8;
    reg Sel_R9;
    reg Sel_R10;
    reg Sel_R11;
    reg Sel_R12;
    reg Sel_R13;
    reg Sel_R14;
    reg Sel_R15;
    reg Sel_PC;
    reg Sel_Sign_Ext;
    reg Sel_ALU, Sel_Bus_1, Sel_Mem;
    reg [state_size-1:0] state, next_state;
    reg err_flag; // add an error flag as well
    
    // wires for individualizing instrution parts
    wire [opcode_size-1:0] opcode = instruction[15:12];
    wire [dest_size-1:0] destination = instruction[11:8]; // Destination register name
    wire [source_size-1:0] source = instruction[7:0]; // source is last 7 bit  can be source 1 + source 2
    wire [src1_size-1:0] source1 = instruction[7:4]; // src1 or Operand 1
    wire [src2_size-1:0] source2 = instruction[3:0]; // Src2 or OPerand 2
    

    //Mux Selectors
    assign Sel_Bus_1_MUX[sel_bus_1_size-1:0] = Sel_R0 ? 0 :
                                           Sel_R1 ? 1 :
                                           Sel_R2 ? 2 :
                                           Sel_R3 ? 3 :
                                           Sel_R4 ? 4 :
                                           Sel_R5 ? 5 :
                                           Sel_R6 ? 6 :
                                           Sel_R7 ? 7 :
                                           Sel_R8 ? 8 :
                                           Sel_R9 ? 9 :
                                           Sel_R10 ? 10 :
                                           Sel_R11 ? 11 :
                                           Sel_R12 ? 12 :
                                           Sel_R13 ? 13 :
                                           Sel_R14 ? 14 :
                                           Sel_R15 ? 15 :
                                           Sel_PC ? 16:
                                           Sel_Sign_Ext ? 17:
                                           5'dx;  // Default value if none of the conditions are met

    assign Sel_Bus_2_MUX[sel_bus_2_size-1:0] = Sel_ALU ? 0 :
                                            Sel_Bus_1 ? 1:
                                            Sel_Mem ? 2:
                                            2'bx; // default value

    
    always @(posedge clk or negedge rst) begin: State_transitions 
        if (rst==0) begin 
            state <= S_idle;
        end 
        else begin 
            state <= next_state;
        end
    end

    always @(state or opcode or source or destination or alu_zero) begin: Output_and_Next_State
        Sel_R0 = 0;
        Sel_R1 = 0;
        Sel_R2 = 0;
        Sel_R3 = 0;
        Sel_R4 = 0;
        Sel_R5 = 0;
        Sel_R6 = 0;
        Sel_R7 = 0;
        Sel_R8 = 0;
        Sel_R9 = 0;
        Sel_R10 = 0;
        Sel_R11 = 0;
        Sel_R12 = 0;
        Sel_R13 = 0;
        Sel_R14 = 0;
        Sel_R15 = 0;
        Sel_PC = 0;
        Sel_Sign_Ext = 0;
        RF_W_Addr = 4'bx; // makes all dec_out = 16'b0 i.e. all Load_Ri = 0

        PC_Ld = 0;
        PC_Inc = 0;
        IR_Ld = 0;
        Sign_Ext_Flag = 0;
        Reg_Y_Ld = 0;
        Reg_A_Ld = 0;
        Reg_Z_Ld = 0;
        D_wr = 0;

        Sel_ALU = 0;
        Sel_Bus_1 = 0;
        Sel_Mem = 0;

        err_flag = 0; // Used for De-bug in simulation
        next_state = state;

        case (state) 
            S_idle: begin //State entered after reset is asserted
                        next_state = S_fet1;
            end
            S_fet1: begin  // Load Address register with the contents of PC
                        next_state = S_fet2;
                        Sel_PC = 1;
                        Sel_Bus_1 = 1;
                        Reg_A_Ld = 1;
            end
            S_fet2: begin // 1. Load the instruction register with the word addressed by the address register, 2. Increent PC to poin to the next location of memory
                        next_state = S_dec_source_1;
                        Sel_Mem = 1;
                        IR_Ld = 1;
                        PC_Inc = 1;
            end
            S_dec_source_1: begin
                        case (opcode) 
                            ADD, SUB, AND, OR, XOR: begin 
                                next_state = S_ex1; // get the 2nd operand as well ans store the result
                                //$display("Entering into ADD, SUB, AND, OR: Before Case ");
                                // $display("instruction = %h", instruction);
                                // $display("source1 = %h", source1);
                                // $display("source2 = %h", source2);
                                // $display("destination = %h", destination);
                                // $display("opcode = %h", opcode);
                                // $display("Sel_5 = %b", Sel_R5);
                                case (source1) // Load the operand to Reg_Y from given register of register file
                                    R0: Sel_R0 = 1;
                                    R1: Sel_R1 = 1;
                                    R2: Sel_R2 = 1;
                                    R3: Sel_R3 = 1;
                                    R4: Sel_R4 = 1;
                                    R5: Sel_R5 = 1;
                                    R6: Sel_R6 = 1;
                                    R7: Sel_R7 = 1;
                                    R8: Sel_R8 = 1;
                                    R9: Sel_R9 = 1;
                                    R10: Sel_R10 = 1;
                                    R11: Sel_R11 = 1;
                                    R12: Sel_R12 = 1;
                                    R13: Sel_R13 = 1;
                                    R14: Sel_R14 = 1;
                                    R15: Sel_R15 = 1;
                                    default err_flag = 1;
                                endcase
                                // $display("After case");
                                // $display("instruction = %h", instruction);
                                // $display("source1 = %h", source1);
                                // $display("source2 = %h", source2);
                                // $display("destination = %h", destination);
                                // $display("opcode = %h", opcode);
                                // $display("Sel_5 = %b", Sel_R5);
                                Sel_Bus_1 = 1;
                                Reg_Y_Ld = 1;
                            end // ADD, SUB, AND, OR, XOR

                            NOT, SLA, SRA: begin 
                                next_state = S_fet1;
                                case (source1) // Load the Operand to ALU insted of Reg Y from given register
                                    R0: Sel_R0 = 1;
                                    R1: Sel_R1 = 1;
                                    R2: Sel_R2 = 1;
                                    R3: Sel_R3 = 1;
                                    R4: Sel_R4 = 1;
                                    R5: Sel_R5 = 1;
                                    R6: Sel_R6 = 1;
                                    R7: Sel_R7 = 1;
                                    R8: Sel_R8 = 1;
                                    R9: Sel_R9 = 1;
                                    R10: Sel_R10 = 1;
                                    R11: Sel_R11 = 1;
                                    R12: Sel_R12 = 1;
                                    R13: Sel_R13 = 1;
                                    R14: Sel_R14 = 1;
                                    R15: Sel_R15 = 1;
                                    default err_flag = 1; 
                                endcase
                                Reg_Z_Ld = 1;
                                Sel_ALU = 1;
                                // Save the alu result to register in the register file again (address given in `destination`)
                                RF_W_Addr = destination;
                            end // NOT, SRA, SLA

                            LI: begin
                                next_state = S_fet1;
                                Sign_Ext_Flag = 1; // Get the sign extension
                                Sel_Sign_Ext = 1; // pass to bus_1
                                Sel_Bus_1 = 1; // pass the sign extended data to bus_2
                                RF_W_Addr = destination; //save the result to destination register in the register file
                            end // LI

                            LW: begin 
                                next_state = S_rd1; // next state to load the memory data to Register
                                Sign_Ext_Flag = 0; // Get memory address for obtaining data without sign extension immediate
                                Sel_Sign_Ext = 1; // get the mem address to the bus 1
                                Sel_Bus_1 = 1; // get the mem address to Bus 2
                                Reg_A_Ld = 1; // Load the Address register with the mem address
                            end // LW

                            SW: begin 
                                next_state = S_wr1; // Next State to load the reg to the memory
                                Sign_Ext_Flag = 0; // Get the memory address for the obtaining data without sign extension immediate
                                Sel_Sign_Ext = 1; // get the mem address to Bus 1
                                Sel_Bus_1 = 1; // get the mem address to Bus 2
                                Reg_A_Ld = 1; // Load the address register with the mem address
                            end // SW

                            BIZ: begin 
                                next_state = S_fet1; // Since BIZ completed in this statement it self
                                case (destination) // Load the operand to Reg_Y from given register of register file
                                    R0: Sel_R0 = 1;
                                    R1: Sel_R1 = 1;
                                    R2: Sel_R2 = 1;
                                    R3: Sel_R3 = 1;
                                    R4: Sel_R4 = 1;
                                    R5: Sel_R5 = 1;
                                    R6: Sel_R6 = 1;
                                    R7: Sel_R7 = 1;
                                    R8: Sel_R8 = 1;
                                    R9: Sel_R9 = 1;
                                    R10: Sel_R10 = 1;
                                    R11: Sel_R11 = 1;
                                    R12: Sel_R12 = 1;
                                    R13: Sel_R13 = 1;
                                    R14: Sel_R14 = 1;
                                    R15: Sel_R15 = 1;
                                    default err_flag = 1;
                                endcase
                                Sel_Bus_1 = 1; // tranfer the reg data to bus2
                                Reg_Y_Ld = 1; // Load the reg data to Reg_Y to check if its 0 or not
                                // This will give you `RF_Ry_Zero` value can be 0 or 1
                                case(RF_Ry_Zero) 
                                    RYis0: begin 
                                        sel_PC_Offset_Update = 0;
                                        PC_Ld = 0;
                                    end 
                                    RYis1: begin
                                        sel_PC_Offset_Update = 1;
                                        PC_Ld = 1; 
                                    end
                                endcase
                            end // BIZ

                            BNZ: begin 
                                next_state = S_fet1; // Since BNZ completed in this statement it self
                                case (destination) // Load the operand to Reg_Y from given register of register file
                                    R0: Sel_R0 = 1;
                                    R1: Sel_R1 = 1;
                                    R2: Sel_R2 = 1;
                                    R3: Sel_R3 = 1;
                                    R4: Sel_R4 = 1;
                                    R5: Sel_R5 = 1;
                                    R6: Sel_R6 = 1;
                                    R7: Sel_R7 = 1;
                                    R8: Sel_R8 = 1;
                                    R9: Sel_R9 = 1;
                                    R10: Sel_R10 = 1;
                                    R11: Sel_R11 = 1;
                                    R12: Sel_R12 = 1;
                                    R13: Sel_R13 = 1;
                                    R14: Sel_R14 = 1;
                                    R15: Sel_R15 = 1;
                                    default err_flag = 1;
                                endcase
                                Sel_Bus_1 = 1; // tranfer the reg data to bus2
                                Reg_Y_Ld = 1; // Load the reg data to Reg_Y to check if its 0 or not
                                // This will give you `RF_Ry_Zero` value can be 0 or 1
                                case(RF_Ry_Zero) 
                                    RYis0: begin // If RF_Ry_Zero = 0 
                                        sel_PC_Offset_Update = 1;
                                        PC_Ld = 1;
                                    end 
                                    RYis1: begin
                                        sel_PC_Offset_Update = 0;
                                        PC_Ld = 0; 
                                    end
                                endcase
                            end // BNZ

                            JAL: begin
                                // Rd = PC + 1
                                next_state = S_fet1; // JAL complete in this state
                                Sel_PC = 1; // Get the PC + 1 from the PC on Bus 1
                                Sel_Bus_1 = 1; // Get the PC+1 on Bus 2
                                RF_W_Addr = destination; // load PC + 1 from Bus_2 to the destination register
                                // Need to update PC to PC + offset (PC is already PC+1)
                                sel_PC_Offset_Update = 1; // select to load the new address (i.e. PC + Offset) to PC
                                PC_Ld = 1; // Load PC with new data
                            end // JAL

                            JMP: begin 
                                next_state = S_fet1;
                                // PC = PC + Offset (Since PC is already incremented to PC + 1)
                                sel_PC_Offset_Update = 1;
                                PC_Ld = 1;
                            end // JR

                            JR: begin 
                                next_state = S_fet1;
                                // PC = Rs (source1)
                                case (source1) // Load the operand to Reg_Y from given register of register file
                                    R0: Sel_R0 = 1;
                                    R1: Sel_R1 = 1;
                                    R2: Sel_R2 = 1;
                                    R3: Sel_R3 = 1;
                                    R4: Sel_R4 = 1;
                                    R5: Sel_R5 = 1;
                                    R6: Sel_R6 = 1;
                                    R7: Sel_R7 = 1;
                                    R8: Sel_R8 = 1;
                                    R9: Sel_R9 = 1;
                                    R10: Sel_R10 = 1;
                                    R11: Sel_R11 = 1;
                                    R12: Sel_R12 = 1;
                                    R13: Sel_R13 = 1;
                                    R14: Sel_R14 = 1;
                                    R15: Sel_R15 = 1;
                                    default err_flag = 1;
                                endcase
                                Sel_Bus_1 = 1; // tranfer the reg data to bus2
                                sel_PC_Offset_Update = 0; // Load the Bus data
                                PC_Ld = 1; // Update the new data from Bus to PC;
                            end 


                        endcase
            end
            S_ex1: begin 
                //Next state will be execute 
                next_state = S_fet1; // Fetch after execution is complete
                // read the seond operand value for ADD, SUB, AND, OR, XOR
                case (source2) // Load the operand to BUS_1 to ALU from given register of register file
                    R0: Sel_R0 = 1;
                    R1: Sel_R1 = 1;
                    R2: Sel_R2 = 1;
                    R3: Sel_R3 = 1;
                    R4: Sel_R4 = 1;
                    R5: Sel_R5 = 1;
                    R6: Sel_R6 = 1;
                    R7: Sel_R7 = 1;
                    R8: Sel_R8 = 1;
                    R9: Sel_R9 = 1;
                    R10: Sel_R10 = 1;
                    R11: Sel_R11 = 1;
                    R12: Sel_R12 = 1;
                    R13: Sel_R13 = 1;
                    R14: Sel_R14 = 1;
                    R15: Sel_R15 = 1;
                    default err_flag = 1;
                endcase
                Reg_Z_Ld = 1; // Enable Zero flag for ALU output
                Sel_ALU = 1; // Send ALU result to BUS 2
                // Now save the result to destinatination register
                RF_W_Addr = destination;
            end
            // S_ex1: begin 
            //     next_state = S_fet1; // Fetch after execution is complete
            //     Reg_Z_Ld = 1; // Enable Zero flag for ALU output
            //     Sel_ALU = 1; // Send ALU result to BUS 2
            //     // Now save the result to destinatination register
            //     RF_W_Addr = destination;
            // end
            S_rd1: begin 
                next_state = S_fet1; // Since load operation is complete
                Sel_Mem = 1; // Get data to Bus 2 from the memory
                RF_W_Addr = destination; //save the result to destination register in the register file
            end
            S_wr1: begin 
                next_state = S_fet1; // Since store operation is complete
                D_wr = 1; // Enable write data present on Bus 1 to the memory
                case (destination) // Load the Operand to BUS_1 insted which is connected to memory
                    R0: Sel_R0 = 1;
                    R1: Sel_R1 = 1;
                    R2: Sel_R2 = 1;
                    R3: Sel_R3 = 1;
                    R4: Sel_R4 = 1;
                    R5: Sel_R5 = 1;
                    R6: Sel_R6 = 1;
                    R7: Sel_R7 = 1;
                    R8: Sel_R8 = 1;
                    R9: Sel_R9 = 1;
                    R10: Sel_R10 = 1;
                    R11: Sel_R11 = 1;
                    R12: Sel_R12 = 1;
                    R13: Sel_R13 = 1;
                    R14: Sel_R14 = 1;
                    R15: Sel_R15 = 1;
                    default err_flag = 1; 
                endcase
                
            end
            default: begin 
                next_state = S_idle;
            end
        endcase
    end
endmodule
