// Use new control Unit (COntrolUnit2)
// FIX (BUG-09): include removed - TT builds from the info.yaml file list; keeping includes causes duplicate-module errors.
// OLD: `include "ProcessingUnit.v"
// FIX (BUG-09): include removed - TT builds from the info.yaml file list; keeping includes causes duplicate-module errors.
// OLD: `include "ControlUnit2.v"
// FIX (BUG-09): include removed - TT builds from the info.yaml file list; keeping includes causes duplicate-module errors.
// OLD: `include "main_memory.v"

// PHASE 2 (BUG-02): boot-loader interface added. The RP2040 loads the program through
// loader.v into main_memory, then releases the CPU. See loader.v header for the protocol.
// OLD: module risc_machine (clk, rst);
// PHASE 3 (BUG-01): observation interface added so the design has real outputs.
// OLD: module risc_machine (clk, rst, load_req, load_strobe, load_data, run, boot_done);
module risc_machine (clk, rst, load_req, load_strobe, load_data, run, boot_done, obs_sel, obs);
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
    // PHASE 2 (BUG-02): loader pins (from TT wrapper / RP2040) + status out
    input load_req;    // high = load session (loader owns memory write port, CPU held)
    input load_strobe; // rising edge = sample one serial bit
    input load_data;   // serial program bit, MSB first
    input run;         // rising edge after boot -> CPU starts from PC=0
    output boot_done;  // high = a load session has completed
    // PHASE 3 (BUG-01): observation port - the TT wrapper exposes one byte of `obs`
    // on uo_out. Without real outputs the whole design is dead logic to synthesis.
    input [2:0] obs_sel;           // which internal value to observe
    output [data_width-1:0] obs;   // selected 16-bit value (wrapper picks a byte)

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
    wire RF_Wr; // FIX (BUG-04): explicit register-file write enable, CU -> PU
    wire D_wr; // data write enable signal

    // PHASE 2 (BUG-02): loader nets
    wire ld_wr;                        // loader word-write pulse
    wire [4:0] ld_addr;                // loader write address (32-word memory)
    wire [data_width-1:0] ld_word;     // assembled program word
    wire load_mode;                    // 1 = loader owns memory write port
    wire cpu_go;                       // 1 = CPU released from reset

    loader LD (
        .clk(clk), .rst(rst),
        .load_req(load_req), .load_strobe(load_strobe), .load_data(load_data), .run(run),
        .ld_wr(ld_wr), .ld_addr(ld_addr), .ld_word(ld_word),
        .load_mode(load_mode), .boot_done(boot_done), .cpu_go(cpu_go)
    );

    // PHASE 2: CPU run gate. Instead of adding S_load/S_ready states to the FSM
    // (original Phase-4 plan), the whole CPU core is simply held in its existing
    // reset while loading and until `run` is latched. Zero FSM surgery, and the
    // CPU can never issue reads/writes while the loader owns the memory. After
    // power-up the CPU also stays off until the first `run` - memory is garbage
    // before a load, so free-running would execute noise.
    wire core_rst = rst & cpu_go;      // active-low, like rst

    //ProcessingUnit
    // FIX (BUG-04): RF_Wr added after RF_W_Addr (positional port list must match ProcessingUnit)
    ProcessingUnit PU (instruction, RF_Ry_Zero, alu_zero, Bus_1, address, mem_read_data, RF_W_Addr, RF_Wr, PC_Ld, PC_Inc, sel_PC_Offset_Update, Sel_Bus_1_MUX, Sign_Ext_Flag, IR_Ld, Reg_Y_Ld, Sel_Bus_2_MUX, Reg_A_Ld, Reg_Z_Ld, clk, core_rst); // PHASE 2: was rst - CPU now gated by loader

    // Control Unit
    ControlUnit2 CU(
        PC_Ld, PC_Inc, sel_PC_Offset_Update, // Control Signals for PC
        RF_W_Addr,  // Address to write into Register File
        RF_Wr, // FIX (BUG-04): new write-enable output of the control unit
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
        clk, core_rst); // PHASE 2: was rst - CPU now gated by loader

    // Memory Unit 
    // PHASE 2 (BUG-02): write port muxed between loader (during load_mode) and CPU.
    // Read port stays on the CPU address - harmless during load since the CPU is held
    // in reset. Memory is now 32 words: only address[4:0] indexes it; the CPU's 8-bit
    // address space simply wraps (programs must stay within 0..31).
    // OLD: main_memory MU(.W_data(Bus_1), .R_data(mem_read_data), .wr(D_wr), .addr(address), .clk(clk));
    main_memory MU(
        .W_data(load_mode ? ld_word : Bus_1),
        .R_data(mem_read_data),
        .wr(load_mode ? ld_wr : D_wr),
        .addr(load_mode ? ld_addr : address[4:0]),
        .clk(clk)
    );

    // PHASE 3: memory-mapped OUTPUT register. Convention: the program stores its
    // final result with SW to address 31; the store still lands in mem[31], but is
    // ALSO captured here, where the host can always read it via the observation mux
    // (no way to address arbitrary memory from outside with the pins we have).
    reg [data_width-1:0] out_reg;
    always @(posedge clk or negedge rst) begin
        if (!rst) out_reg <= {data_width{1'b0}};
        else if (!load_mode && D_wr && (address[4:0] == 5'd31)) out_reg <= Bus_1;
    end

    // PHASE 3: observation mux (obs_sel from ui_in[6:4] in the TT wrapper)
    assign obs = (obs_sel == 3'd0) ? out_reg :                        // final result
                 (obs_sel == 3'd1) ? {8'b0, address} :                // current mem address
                 (obs_sel == 3'd2) ? Bus_1 :                          // live datapath bus
                 (obs_sel == 3'd3) ? instruction :                    // current instruction
                 (obs_sel == 3'd4) ? mem_read_data :                  // mem word at CPU addr
                 (obs_sel == 3'd5) ? {11'b0, load_mode, cpu_go, boot_done, alu_zero, RF_Ry_Zero} : // status flags
                 out_reg;                                             // defined default (BUG-07 discipline)
    
endmodule