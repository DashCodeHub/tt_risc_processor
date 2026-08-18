// ============================================================================
// tb_bootload.v - PHASE 2 regression: models the RP2040 host end-to-end.
// Serial-loads a program (protocol identical to what MicroPython will do),
// verifies the CPU is inert before `run`, releases it, checks results, then
// runs a SECOND load session to prove reloadability.
// ============================================================================
`timescale 1ns/1ps
module tb_bootload;
    reg clk = 1'b1;
    always #5 clk = ~clk;               // 100 MHz chip clock

    reg rst, load_req, load_strobe, load_data, run;
    wire boot_done;

    risc_machine UUT (
        .clk(clk), .rst(rst),
        .load_req(load_req), .load_strobe(load_strobe),
        .load_data(load_data), .run(run), .boot_done(boot_done)
    );

    // ---- RP2040-style bit-bang: one word, MSB first, strobe ~10x slower than clk
    task send_word(input [15:0] w);
        integer i;
        begin
            for (i = 15; i >= 0; i = i - 1) begin
                load_data = w[i];
                #23 load_strobe = 1'b1;   // deliberately unaligned to clk
                #52 load_strobe = 1'b0;
                #31;
            end
        end
    endtask

    // Program (branch targets are relative to the branch's own address - ISA
    // convention discovered in Phase 1: compute_offset does A+B-1 with A=PC+1):
    //  0: LI  R1,3        3: ADD R2,R2,R3    6: BIZ R1,+3 -> 9   9: SW R2,[30]
    //  1: LI  R2,0        4: SUB R1,R1,R3    7: LI R4,255 poison 10: JMP +3 -> 13
    //  2: LI  R3,1        5: BNZ R1,-2 -> 3  8: LI R2,255 poison 11,12: poison
    //  13: SW R3,[31]     14: JMP +0 -> 14 (halt spin)
    reg [15:0] prog [0:14];
    integer k;
    initial begin
        prog[0]  = {4'b1000, 4'd1, 8'd3};
        prog[1]  = {4'b1000, 4'd2, 8'd0};
        prog[2]  = {4'b1000, 4'd3, 8'd1};
        prog[3]  = {4'b0000, 4'd2, 4'd2, 4'd3};
        prog[4]  = {4'b0001, 4'd1, 4'd1, 4'd3};
        prog[5]  = {4'b1100, 4'd1, 8'hFE};   // BNZ R1 -> 3
        prog[6]  = {4'b1011, 4'd1, 8'h03};   // BIZ R1 -> 9
        prog[7]  = {4'b1000, 4'd4, 8'd255};  // poison
        prog[8]  = {4'b1000, 4'd2, 8'd255};  // poison
        prog[9]  = {4'b1010, 4'd2, 8'd30};   // SW R2 -> [30]
        prog[10] = {4'b1110, 4'd0, 8'h03};   // JMP -> 13
        prog[11] = {4'b1000, 4'd2, 8'd254};  // poison
        prog[12] = {4'b1000, 4'd2, 8'd253};  // poison
        prog[13] = {4'b1010, 4'd3, 8'd31};   // SW R3 -> [31]
        prog[14] = {4'b1110, 4'd0, 8'h00};   // JMP -> 14 (spin)
    end

    integer errors = 0;
    initial begin
        rst = 0; load_req = 0; load_strobe = 0; load_data = 0; run = 0;
        #17 rst = 1;

        // --- CPU must be inert before any run: PC frozen, no mem writes ---
        #200;
        if (UUT.PU.PC_addr !== 16'd0) begin
            $display("FAIL: CPU active before run (PC=%0d)", UUT.PU.PC_addr); errors = errors + 1;
        end

        // --- load session 1 ---
        #10 load_req = 1;
        #40;
        for (k = 0; k <= 14; k = k + 1) send_word(prog[k]);
        #40 load_req = 0;
        #40;
        if (boot_done !== 1'b1) begin $display("FAIL: boot_done not set"); errors = errors + 1; end
        if (UUT.MU.memory256x16[5] !== prog[5]) begin
            $display("FAIL: mem[5]=%h expected %h", UUT.MU.memory256x16[5], prog[5]); errors = errors + 1;
        end

        // --- run ---
        #20 run = 1;
        #2000; // plenty for ~40 instructions of multicycle execution
        if (UUT.MU.memory256x16[30] !== 16'd3) begin
            $display("FAIL: mem[30]=%0d expected 3", UUT.MU.memory256x16[30]); errors = errors + 1;
        end
        if (UUT.MU.memory256x16[31] !== 16'd1) begin
            $display("FAIL: mem[31]=%0d expected 1", UUT.MU.memory256x16[31]); errors = errors + 1;
        end

        // --- load session 2: reload with a trivial program, prove restartability ---
        run = 0; // (run is latched inside; dropping the pad is just tidy TB behavior)
        #20 load_req = 1; #40;
        send_word({4'b1000, 4'd5, 8'd42});  // 0: LI R5,42
        send_word({4'b1010, 4'd5, 8'd20});  // 1: SW R5 -> [20]
        send_word({4'b1110, 4'd0, 8'h00});  // 2: JMP -> 2 (spin)
        #40 load_req = 0; #40;
        run = 1;
        #800;
        if (UUT.MU.memory256x16[20] !== 16'd42) begin
            $display("FAIL: reload mem[20]=%0d expected 42", UUT.MU.memory256x16[20]); errors = errors + 1;
        end

        if (errors == 0) $display("BOOTLOAD TEST: PASS (load, inert-before-run, exec, boot_done, reload all OK)");
        else             $display("BOOTLOAD TEST: FAIL (%0d errors)", errors);
        $finish;
    end
endmodule