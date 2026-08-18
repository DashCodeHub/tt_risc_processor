/*
 * project.v - Tiny Tapeout top-level wrapper (PHASE 3, fixes BUG-01)
 *
 * tt_um wrapper around risc_machine: a 16-bit multicycle RISC that is
 * boot-loaded over a 2-pin serial link by the demo board's RP2040 and then
 * runs from its 32x16 on-chip memory ("Option B - boot-load then run").
 *
 * PIN MAP (must match docs/info.md and the tracker §0):
 *   ui_in[0]  load_req    high = load session (loader owns memory, CPU held in reset)
 *   ui_in[1]  run         rising edge after boot_done -> CPU starts at PC=0
 *   ui_in[2]  load_strobe rising edge = sample one serial bit
 *   ui_in[3]  load_data   serial program bit, MSB first within each 16-bit word
 *   ui_in[6:4] obs_sel    000 out_reg (result, see below)  001 address
 *                         010 Bus_1   011 instruction  100 mem_read_data
 *                         101 status flags {load_mode,cpu_go,boot_done,alu_zero,rf_ry_zero}
 *   ui_in[7]  byte_sel    0 = obs[7:0] on uo_out, 1 = obs[15:8]
 *   uo_out[7:0]           selected observation byte
 *   uio[7]    boot_done   (output) high = a load session has completed
 *   uio[6:0]              unused, driven 0 / hi-Z inputs disabled
 *
 * Result convention: programs store their final answer with SW to address 31;
 * that value is captured in a dedicated out_reg readable at obs_sel=000 forever
 * after, regardless of what the buses are doing.
 *
 * IMPORTANT: the module name below must match `top_module` in info.yaml and the
 * instantiation in test/tb.v - all three identical, or the build/test breaks.
 */

`default_nettype none

module tt_um_dash_lucas_risc (
    input  wire [7:0] ui_in,    // dedicated inputs
    output wire [7:0] uo_out,   // dedicated outputs
    input  wire [7:0] uio_in,   // bidirectional: input path (unused)
    output wire [7:0] uio_out,  // bidirectional: output path
    output wire [7:0] uio_oe,   // bidirectional: enable (1 = output)
    input  wire       ena,      // always 1 when the design is powered (unused)
    input  wire       clk,      // system clock
    input  wire       rst_n     // active-low reset
);

    wire        boot_done;
    wire [15:0] obs;

    risc_machine core (
        .clk         (clk),
        .rst         (rst_n),      // core resets are already active-low async
        .load_req    (ui_in[0]),
        .load_strobe (ui_in[2]),
        .load_data   (ui_in[3]),
        .run         (ui_in[1]),
        .boot_done   (boot_done),
        .obs_sel     (ui_in[6:4]),
        .obs         (obs)
    );

    // observation byte select
    assign uo_out = ui_in[7] ? obs[15:8] : obs[7:0];

    // bidirectional pins: only uio[7] used, as an output for boot_done
    assign uio_out = {boot_done, 7'b0000000};
    assign uio_oe  = 8'b1000_0000;

    // silence lint on intentionally-unused inputs
    wire _unused = &{ena, uio_in, 1'b0};

endmodule