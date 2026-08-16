//ALU for RISC Processor
//Operations to Perform in ALU given by Instruction Set
/*
    Operation       Opcode      Description
-----------------------------------------------
    ADD             0000        Rd <=Rd = Rs + Rt
    SUB             0001        Rd <= Rs - Rt
    AND             0010        Rd <= Rs & Rt
    OR              0011        Rd <= Rs + Rt
    XOR             0100        Rd <= Rs + Rt
    NOT             0101        Rd <= ~ Rs
    SLA             0110        Rd <= Rs<< 1
    SRA             0111        Rd <= Rs>>1 
-----------------------------------------------
    LI              1000        Rd <= 8-bit Sign extented Immediate (The 8-bit immediate in the instruction word is sign extended to 16 bit) and written into the register
    LW              1001        Rd <= Mem[addr] The memory word specified by the address "addr" is loaded into the register Rd
    SW              1010        Mem[addr] <= Rt The data in regiter Rt is stored in loacation "addr" of Mem
    BIZ             1011        PC = PC + 1 + Offset, If all the bits in registe Rs are zero then the current Program Count (PC + 1) is offset to (PC + 1 + Offset). The count is offset from PC + 1 because it is increamented and stored during fetch cycle.
    BNZ             1100        PC = PC + 1 + Offset,  If Rs != 0
    JAL             1101        Rd = PC + 1 and PC = PC + 1 + Offset, Jump and Link instruction would write current program count in registe Rd and offser the program count to PC + 1 + Offset
    JMP             1110        Rd = PC + 1 and PC = PC + 1 + Offset, Unconditional jump instruction will offse2t the program count PC + 1 + Offset
    JR              1111        PC = Rs, Jump Return instruction will set the set Progm Count to the one previously stored in JAL
*/

/*
Design for ALU
---------------
Inputs = A , B (16 bit operands)
Output = out(res), 
*/

module alu(
    alu_A,
    alu_B,
    alu_OUT,
    opcode,
    alu_zero_flag
); 
    //datawidths
    parameter data_width = 16;
    parameter opcode_size = 4;
    
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
    
    // Input Output Declaration 
    input [data_width-1:0] alu_A; // Rs in 2's Complement
    input [data_width-1:0] alu_B; //Rt in 2's Complement
    input [opcode_size-1:0] opcode; // Opcode
    output [data_width-1:0] alu_OUT; //Rd in 2's Complenent
    output alu_zero_flag; // If output is 0

    // Reg Wire declation
    reg [data_width-1:0] alu_OUT;

    //Assign `alu_zero_flag` if alu_OUT is 0
    assign alu_zero_flag = ~|alu_OUT;

    // Choose what operation need to do
    always @(opcode or alu_A or alu_B) begin 
        case(opcode) 
            ADD:   alu_OUT = alu_A + alu_B;
            SUB:   alu_OUT = alu_A - alu_B;
            AND:   alu_OUT = alu_A & alu_B;
            OR:    alu_OUT = alu_A | alu_B;
            XOR:   alu_OUT = alu_A ^ alu_B;
            NOT:   alu_OUT = ~alu_B;
            SLA:   alu_OUT = alu_B << 1;
            SRA:   alu_OUT = alu_B >> 1;
            default:    alu_OUT = 16'b0;
        endcase
    end
endmodule
