# SPDX-FileCopyrightText: © 2026 Priyabrata Dash
# SPDX-License-Identifier: Apache-2.0
#
# Phase 6: cocotb port of the verified pin-only regression (tb_wrapper.v /
# tb_bootload.v). Drives ONLY the real TT pins and reads results ONLY through
# uo_out / uio_out, so the very same test passes in RTL simulation, gate-level
# simulation (GL_TEST), and - later - against the physical chip via the RP2040.
#
# Pin map (must match src/project.v and info.yaml):
#   ui_in[0] load_req   ui_in[1] run   ui_in[2] load_strobe   ui_in[3] load_data
#   ui_in[6:4] obs_sel  ui_in[7] byte_sel
#   uo_out = selected observation byte      uio_out[7] = boot_done
#   obs_sel: 0=out_reg(result) 1=address 2=Bus_1 3=instruction 4=mem_read 5=flags

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

# ---- pin bit positions on ui_in ----
LOAD_REQ = 1 << 0
RUN      = 1 << 1
STROBE   = 1 << 2
DATA     = 1 << 3
BYTE_SEL = 1 << 7


def obs_sel(sel):
    """Value to OR into ui_in for a given observation select (0..5)."""
    return (sel & 0x7) << 4


def instr(op, dest, src8):
    """Assemble one 16-bit instruction: [15:12] op, [11:8] dest, [7:0] src."""
    return ((op & 0xF) << 12) | ((dest & 0xF) << 8) | (src8 & 0xFF)


async def send_word(dut, ui, word):
    """Shift one 16-bit word into the loader, MSB first (RP2040 protocol).

    Each strobe phase is held for several clock cycles because the loader
    synchronizes pad inputs through 2 flip-flops before edge-detecting.
    Returns the updated ui_in shadow value.
    """
    for i in range(15, -1, -1):
        bit = (word >> i) & 1
        ui = (ui | DATA) if bit else (ui & ~DATA)
        dut.ui_in.value = ui
        await ClockCycles(dut.clk, 3)
        dut.ui_in.value = ui | STROBE          # strobe rising edge
        await ClockCycles(dut.clk, 4)
        ui = ui & ~STROBE
        dut.ui_in.value = ui                   # strobe falling edge
        await ClockCycles(dut.clk, 4)
    return ui


async def read_obs16(dut, ui, sel):
    """Read a full 16-bit observation value through the 8-bit uo_out port."""
    ui = (ui & ~(0x7 << 4) & ~BYTE_SEL) | obs_sel(sel)
    dut.ui_in.value = ui                       # low byte
    await ClockCycles(dut.clk, 3)
    lo = dut.uo_out.value.integer
    dut.ui_in.value = ui | BYTE_SEL            # high byte
    await ClockCycles(dut.clk, 3)
    hi = dut.uo_out.value.integer
    dut.ui_in.value = ui
    return (hi << 8) | lo, ui


@cocotb.test()
async def test_bootload_and_run(dut):
    """Serial-load a program via the RP2040 protocol, run it, verify result."""
    dut._log.info("Start")

    clock = Clock(dut.clk, 100, units="ns")    # 10 MHz, matching info.yaml
    cocotb.start_soon(clock.start())

    # ---- reset ----
    ui = 0
    dut.ena.value = 1
    dut.ui_in.value = ui
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)

    # ---- CPU must be inert before any run: memory is powerup garbage ----
    # boot_done must be low, and uio_oe must expose exactly bit 7 as output.
    assert dut.uio_oe.value.integer == 0x80, \
        f"uio_oe={dut.uio_oe.value} expected 0x80 (only boot_done is an output)"
    assert (dut.uio_out.value.integer >> 7) & 1 == 0, "boot_done high before any load"

    # ---- program: R3 = 5 + 7, store to addr 31 (captured into out_reg) ----
    #  0: LI  R1,5
    #  1: LI  R2,7
    #  2: ADD R3,R1,R2   (src field packs src1=1, src2=2)
    #  3: SW  R3,[31]
    #  4: JMP +0 -> spins at 4 (target = branch addr + offset, A+B-1 semantics)
    program = [
        instr(0b1000, 1, 5),
        instr(0b1000, 2, 7),
        instr(0b0000, 3, (1 << 4) | 2),
        instr(0b1010, 3, 31),
        instr(0b1110, 0, 0),
    ]

    # ---- load session ----
    ui |= LOAD_REQ
    dut.ui_in.value = ui
    await ClockCycles(dut.clk, 6)
    for w in program:
        ui = await send_word(dut, ui, w)
    ui &= ~LOAD_REQ
    dut.ui_in.value = ui
    await ClockCycles(dut.clk, 6)

    assert (dut.uio_out.value.integer >> 7) & 1 == 1, "boot_done not set after load"
    dut._log.info("Program loaded, boot_done high")

    # ---- run ----
    ui |= RUN
    dut.ui_in.value = ui
    await ClockCycles(dut.clk, 200)            # ~5 instructions x ~5 cycles << 200

    # ---- result readback through pins only: obs_sel=0 -> out_reg ----
    result, ui = await read_obs16(dut, ui, 0)
    dut._log.info(f"out_reg = {result} (expected 12)")
    assert result == 12, f"out_reg={result}, expected 5+7=12"

    # ---- status flags view: obs_sel=5, low byte ----
    # bits: [4]=load_mode [3]=cpu_go [2]=boot_done [1]=alu_zero [0]=rf_ry_zero
    ui = (ui & ~(0x7 << 4) & ~BYTE_SEL) | obs_sel(5)
    dut.ui_in.value = ui
    await ClockCycles(dut.clk, 3)
    flags = dut.uo_out.value.integer
    assert (flags >> 2) & 1 == 1, f"flags={flags:08b}: boot_done should be 1"
    assert (flags >> 3) & 1 == 1, f"flags={flags:08b}: cpu_go should be 1"
    assert (flags >> 4) & 1 == 0, f"flags={flags:08b}: load_mode should be 0"

    dut._log.info("Bootload + execute + readback: PASS")


@cocotb.test()
async def test_reload(dut):
    """Second load session must freeze the CPU and accept a new program."""
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    ui = 0
    dut.ena.value = 1
    dut.ui_in.value = ui
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)

    async def load_and_run(program, ui):
        ui |= LOAD_REQ
        dut.ui_in.value = ui
        await ClockCycles(dut.clk, 6)
        for w in program:
            ui = await send_word(dut, ui, w)
        ui &= ~LOAD_REQ
        dut.ui_in.value = ui
        await ClockCycles(dut.clk, 6)
        ui |= RUN
        dut.ui_in.value = ui
        await ClockCycles(dut.clk, 200)
        return ui

    # session 1: out_reg = 5+7 = 12
    ui = await load_and_run([
        instr(0b1000, 1, 5),
        instr(0b1000, 2, 7),
        instr(0b0000, 3, (1 << 4) | 2),
        instr(0b1010, 3, 31),
        instr(0b1110, 0, 0),
    ], ui)
    r1, ui = await read_obs16(dut, ui, 0)
    assert r1 == 12, f"session 1: out_reg={r1}, expected 12"

    # session 2: reload -> out_reg = 42 (LI sign-extends 8-bit imm; 42 is positive)
    ui &= ~RUN                                  # tidy: drop run pad before reload
    dut.ui_in.value = ui
    await ClockCycles(dut.clk, 3)
    ui = await load_and_run([
        instr(0b1000, 5, 42),
        instr(0b1010, 5, 31),
        instr(0b1110, 0, 0),
    ], ui)
    r2, ui = await read_obs16(dut, ui, 0)
    assert r2 == 42, f"session 2 (reload): out_reg={r2}, expected 42"

    dut._log.info("Reload: PASS")