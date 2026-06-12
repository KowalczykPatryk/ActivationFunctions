import cocotb  # type: ignore
from cocotb.clock import Clock  # type: ignore
from cocotb.triggers import RisingEdge, ReadOnly, NextTimeStep  # type: ignore
from collections import deque
import math


def fixed_to_float(val: int, width: int, q: int) -> float:
    if val >= (1 << (width - 1)):
        val -= (1 << width)
    return val / (1 << q)


def float_to_fixed(x: float, width: int, q: int) -> int:
    raw = int(round(x * (1 << q)))

    max_val = (1 << (width - 1)) - 1
    min_val = -(1 << (width - 1))

    return max(min(raw, max_val), min_val)


INPUT_W = 16
OUTPUT_W = 16
Q_IN = 12
Q_OUT = 12

X_MIN = -4.0
X_MAX = 4.0
STEPS = 2000

MAX_LATENCY_PROBE = 64
CLK_PERIOD_NS = 10

DEBUG_ALL = False
DEBUG_ERROR_THRESHOLD = 0.05


async def do_reset(dut):

    await NextTimeStep()

    dut.rst_n.value = 0
    dut.x.value = 0

    for _ in range(4):
        await RisingEdge(dut.clk)

    dut.rst_n.value = 1

    await RisingEdge(dut.clk)
    await ReadOnly()


async def auto_detect_latency(dut):

    probe = float_to_fixed(1.0, INPUT_W, Q_IN)

    await NextTimeStep()
    dut.x.value = probe

    baseline = int(dut.y.value)

    for cycle in range(1, MAX_LATENCY_PROBE + 1):

        await RisingEdge(dut.clk)
        await ReadOnly()

        if int(dut.y.value) != baseline:
            return cycle

    raise RuntimeError(
        f"Unable to detect latency within {MAX_LATENCY_PROBE} cycles"
    )


@cocotb.test()
async def test_tanh_generic(dut):

    cocotb.start_soon(
        Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start()
    )

    await do_reset(dut)
    latency = await auto_detect_latency(dut)

    dut._log.info(f"Detected latency = {latency}")

    await do_reset(dut)

    x_vals = [
        X_MIN + (X_MAX - X_MIN) * k / (STEPS - 1)
        for k in range(STEPS)
    ]

    scoreboard = deque()

    errors = []
    refs = []
    hws = []
    xs = []
    raws = []

    for idx, x in enumerate(x_vals):

        ref = math.tanh(x)

        await NextTimeStep()

        dut.x.value = float_to_fixed(
            x,
            INPUT_W,
            Q_IN
        )

        scoreboard.append((idx, x, ref))

        await RisingEdge(dut.clk)
        await ReadOnly()

        if len(scoreboard) > latency:

            exp_idx, exp_x, exp_ref = scoreboard.popleft()

            raw_y = int(dut.y.value)

            hw = fixed_to_float(
                raw_y,
                OUTPUT_W,
                Q_OUT
            )

            err = abs(exp_ref - hw)

            xs.append(exp_x)
            refs.append(exp_ref)
            hws.append(hw)
            raws.append(raw_y)
            errors.append(err)


    dut._log.info(
        f"FLUSH START: scoreboard size = {len(scoreboard)}"
    )

    dut._log.info(
        f"Last driven x = {x_vals[-1]:.6f}"
    )

    for flush_idx in range(latency):

        await RisingEdge(dut.clk)
        await ReadOnly()

        dut._log.info(
            f"FLUSH[{flush_idx}] "
            f"raw=0x{int(dut.y.value):04X}"
        )

        exp_idx, exp_x, exp_ref = scoreboard.popleft()

        raw_y = int(dut.y.value)

        hw = fixed_to_float(
            raw_y,
            OUTPUT_W,
            Q_OUT
        )

        err = abs(exp_ref - hw)

        xs.append(exp_x)
        refs.append(exp_ref)
        hws.append(hw)
        raws.append(raw_y)
        errors.append(err)

        dut._log.info(
            f"FLUSH[{flush_idx}] "
            f"idx={exp_idx} "
            f"x={exp_x:.6f} "
            f"ref={exp_ref:.6f} "
            f"hw={hw:.6f} "
            f"raw=0x{raw_y:04X} "
            f"err={err:.6f}"
        )

    assert len(errors) == STEPS
    assert len(scoreboard) == 0

    max_idx = max(
        range(len(errors)),
        key=lambda i: errors[i]
    )

    max_error = errors[max_idx]

    mae = sum(errors) / len(errors)

    rmse = math.sqrt(
        sum(e * e for e in errors) / len(errors)
    )

    dut._log.info("==== TANH BENCHMARK ====")

    dut._log.info(
        f"Latency : {latency} cycle(s) "
        f"({latency * CLK_PERIOD_NS} ns)"
    )

    dut._log.info(f"MaxE    : {max_error:.6f}")
    dut._log.info(f"MAE     : {mae:.6f}")
    dut._log.info(f"RMSE    : {rmse:.6f}")

    dut._log.info(
        f"WORST   : "
        f"idx={max_idx}, "
        f"x={xs[max_idx]:.6f}, "
        f"ref={refs[max_idx]:.6f}, "
        f"hw={hws[max_idx]:.6f}, "
        f"raw=0x{raws[max_idx]:04X}, "
        f"err={errors[max_idx]:.6f}"
    )

    dut._log.info("==== LAST 20 SAMPLES ====")

    start = max(0, STEPS - 20)

    for i in range(start, STEPS):

        dut._log.info(
            f"idx={i:4d} "
            f"x={xs[i]: .6f} "
            f"ref={refs[i]: .6f} "
            f"hw={hws[i]: .6f} "
            f"raw=0x{raws[i]:04X} "
            f"err={errors[i]: .6f}"
        )

    dut._log.info("==== LARGE ERRORS ====")

    for i in range(STEPS):

        if errors[i] > DEBUG_ERROR_THRESHOLD:

            dut._log.info(
                f"idx={i:4d} "
                f"x={xs[i]: .6f} "
                f"ref={refs[i]: .6f} "
                f"hw={hws[i]: .6f} "
                f"raw=0x{raws[i]:04X} "
                f"err={errors[i]: .6f}"
            )

    if DEBUG_ALL:

        dut._log.info("==== ALL SAMPLES ====")

        for i in range(STEPS):

            dut._log.info(
                f"idx={i:4d} "
                f"x={xs[i]: .6f} "
                f"ref={refs[i]: .6f} "
                f"hw={hws[i]: .6f} "
                f"raw=0x{raws[i]:04X} "
                f"err={errors[i]: .6f}"
            )

    dut._log.info(
        f"Config : "
        f"INPUT_W={INPUT_W} "
        f"OUTPUT_W={OUTPUT_W} "
        f"Q_IN={Q_IN} "
        f"Q_OUT={Q_OUT} "
        f"STEPS={STEPS}"
    )