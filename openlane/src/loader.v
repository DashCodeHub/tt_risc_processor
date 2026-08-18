// ============================================================================
// loader.v - PHASE 2/3 (BUG-02): serial boot-loader for the RP2040-hosted flow
// ============================================================================
// The Tiny Tapeout demo board's RP2040 streams the program into on-chip memory
// before the CPU is released (architecture "Option B - boot-load then run").
//
// Protocol (all pins sampled in the chip clock domain, RP2040 side is MicroPython
// bit-banging, i.e. orders of magnitude slower than clk - safe to synchronize):
//   1. Raise load_req.            -> loader takes over memory write port,
//                                     write pointer resets to 0, boot_done falls,
//                                     CPU is held in reset by run gate (see risc_machine2.v).
//   2. For each 16-bit word, MSB first:
//        put bit on load_data, pulse load_strobe high then low.
//      After the 16th bit of a word, the loader writes the word to mem[pointer]
//      and increments the pointer. Words land at 0,1,2,... automatically.
//   3. Drop load_req.             -> boot_done rises (visible on a pin).
//   4. Raise run.                 -> CPU reset is released, execution starts at PC=0.
//      A new load session can be started at any time by raising load_req again.
//
// Why 2-FF synchronizers + edge detect: load_strobe/load_req/run come from chip
// pads driven by an asynchronous microcontroller. Sampling them directly risks
// metastability; acting on levels instead of edges would shift one bit per clk
// cycle. We therefore synchronize each input and act on detected rising edges.
// ============================================================================

module loader(
    clk,
    rst,            // chip-level active-low async reset (TT rst_n)
    load_req,       // pad: high = load session in progress
    load_strobe,    // pad: rising edge = sample one bit of load_data
    load_data,      // pad: serial program bit, MSB first within each word
    run,            // pad: rising edge (after boot_done) = start the CPU
    ld_wr,          // to memory mux: 1-cycle word-write pulse
    ld_addr,        // to memory mux: word write address (auto-increment)
    ld_word,        // to memory mux: assembled 16-bit word
    load_mode,      // 1 = loader owns the memory write port (CPU held off)
    boot_done,      // 1 = at least one load session completed since reset
    cpu_go          // 1 = CPU allowed out of reset (run latched, not loading)
);
    parameter data_width = 16;
    parameter addr_width = 5;  // matches main_memory depth=32

    input clk, rst;
    input load_req, load_strobe, load_data, run;
    output ld_wr;
    output [addr_width-1:0] ld_addr;
    output [data_width-1:0] ld_word;
    output load_mode;
    output boot_done;
    output cpu_go;

    // ---- 2-FF synchronizers for the asynchronous pad inputs ----
    reg [1:0] req_sync, strobe_sync, run_sync;
    reg       data_sync1, data_sync2;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            req_sync    <= 2'b00;
            strobe_sync <= 2'b00;
            run_sync    <= 2'b00;
            data_sync1  <= 1'b0;
            data_sync2  <= 1'b0;
        end else begin
            req_sync    <= {req_sync[0],    load_req};
            strobe_sync <= {strobe_sync[0], load_strobe};
            run_sync    <= {run_sync[0],    run};
            data_sync1  <= load_data;
            data_sync2  <= data_sync1;
        end
    end

    // ---- edge detectors (previous synchronized value vs current) ----
    reg strobe_d, req_d, run_d;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            strobe_d <= 1'b0;
            req_d    <= 1'b0;
            run_d    <= 1'b0;
        end else begin
            strobe_d <= strobe_sync[1];
            req_d    <= req_sync[1];
            run_d    <= run_sync[1];
        end
    end
    wire strobe_rise = strobe_sync[1] & ~strobe_d;
    wire req_rise    = req_sync[1]    & ~req_d;
    wire req_fall    = ~req_sync[1]   & req_d;
    wire run_rise    = run_sync[1]    & ~run_d;

    // ---- shift-in machinery ----
    reg [data_width-1:0] shreg;      // bits assemble here, MSB first
    reg [3:0]            bit_cnt;    // 0..15 within a word
    reg [addr_width-1:0] wptr;       // auto-incrementing word address
    reg                  wr_pulse;   // 1-cycle write strobe to memory
    reg                  loading;    // = load_mode
    reg                  done;       // = boot_done
    reg                  go;         // = cpu_go (run latched)

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            shreg    <= {data_width{1'b0}};
            bit_cnt  <= 4'd0;
            wptr     <= {addr_width{1'b0}};
            wr_pulse <= 1'b0;
            loading  <= 1'b0;
            done     <= 1'b0;
            go       <= 1'b0;   // CPU stays in reset after power-up until commanded:
                                // memory content is undefined garbage before a load,
                                // so free-running from PC=0 would execute noise.
        end else begin
            wr_pulse <= 1'b0;  // default: write strobe is a single-cycle pulse

            if (req_rise) begin            // new load session
                loading <= 1'b1;
                done    <= 1'b0;
                go      <= 1'b0;           // stop the CPU while its memory changes
                bit_cnt <= 4'd0;
                wptr    <= {addr_width{1'b0}};
            end else if (req_fall) begin   // session finished
                loading <= 1'b0;
                done    <= 1'b1;
            end

            if (loading && strobe_rise) begin
                shreg <= {shreg[data_width-2:0], data_sync2}; // shift in, MSB first
                if (bit_cnt == 4'd15) begin
                    bit_cnt  <= 4'd0;
                    wr_pulse <= 1'b1;      // word complete -> write next cycle
                end else begin
                    bit_cnt <= bit_cnt + 4'd1;
                end
            end

            if (wr_pulse) begin
                wptr <= wptr + {{(addr_width-1){1'b0}}, 1'b1}; // advance after the write
            end

            if (run_rise && !loading) begin
                go <= 1'b1;                // latch: CPU released until next load_req
            end
        end
    end

    assign ld_wr     = wr_pulse;
    assign ld_addr   = wptr;
    assign ld_word   = shreg;
    assign load_mode = loading;
    assign boot_done = done;
    assign cpu_go    = go;

endmodule