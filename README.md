# 📈 Stock Market Signal Generator Using FPGA


![FPGA](https://img.shields.io/badge/Platform-FPGA%20%7C%20Zynq%207020-E94560?style=for-the-badge)
![Language](https://img.shields.io/badge/Language-Verilog%20HDL-0F3460?style=for-the-badge)
![Tool](https://img.shields.io/badge/Tool-Xilinx%20Vivado-F5A623?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Simulated%20%26%20Verified-22CC66?style=for-the-badge)

A hardware-based real-time trading signal generator that produces BUY / SELL / HOLD decisions using EMA crossover, RSI, and volume spike detection — implemented entirely in Verilog HDL.



</div>

What This Project Does
Traditional software trading systems suffer from OS-level latency, non-deterministic execution, and sequential processing bottlenecks. This project implements the same financial indicators **directly in hardware** on an FPGA, achieving:
- ✅ **10–20 ns effective latency** per decision cycle at 100 MHz
- ✅ **Parallel computation** — EMA-14, EMA-50, RSI-14, and Volume Filter all run simultaneously
- ✅ **Deterministic behaviour** — no OS, no scheduler, no cache misses
- ✅ **100 million samples/second** throughput
The system reads stock price and volume data, computes three financial indicators in hardware, and outputs a **BUY**, **SELL**, or **HOLD** signal on every clock cycle.

## How It Works


price_in ──► Shift Reg (SR14) ──► EMA-14 ──┐
         └► Shift Reg (SR50) ──► EMA-50 ──┤
                                            ├──► Signal Logic ──► BUY / SELL / HOLD
         ──► RSI-14 ────────────────────────┤
volume_in──► Volume Filter (spike detect) ──┘
```

### Signal Decision Logic

| Condition | Output |
|---|---|
| EMA-14 crosses **above** EMA-50 | **BUY** (`2'b01`) |
| EMA-14 crosses **below** EMA-50 | **SELL** (`2'b10`) |
| No crossover detected | **HOLD** (`2'b00`) |

---

## 📐 System Architecture
The design is fully modular with 7 RTL source files and 1 testbench:
stock_signal_top.v          ← Top-level integration module
├── shift_reg.v             ← Parameterized N-element price/volume buffer
├── sma.v                   ← Simple Moving Average (running sum + reciprocal multiply)
├── ema.v                   ← Exponential Moving Average (Q0.16 alpha, first-price seeded)
├── rsi_calc.v              ← RSI-14 using Wilder's smoothing + 64-bit integer division
├── volume_filter.v         ← 20-period rolling average + 1.5× spike detection
└── signal_logic.v          ← Crossover detection via previous-state register
tb_stock_signal.v           ← Testbench (3-phase trend simulation

## Financial Indicators — Hardware Implementation

### 1. Exponential Moving Average (EMA)
EMAₜ = α × Priceₜ + (1 − α) × EMAₜ

| Parameter | EMA-14 (Fast) | EMA-50 (Slow) |
|---|---|---|
| Period (N) | 14 | 50 |
| Alpha (α) | 0.1333 | 0.0392 |
| Alpha in Q0.16 | 8738 | 2571 |

**Implementation notes:**
- Uses Q16.16 fixed-point format — all prices multiplied by 65536
- EMA seeded to first price sample to avoid 50+ cycle cold-start error
- Single multiply-add per clock cycle, fully pipelined

### 2. Relative Strength Index (RSI-14)
RSI = 100 × AvgGain / (AvgGain + AvgLoss)
```

- Uses **Wilder's Smoothing** — no need to store all 14 price changes
- 64-bit intermediate values prevent overflow during division
- RSI > 70 → Overbought | RSI < 30 → Oversold

### 3. Volume Spike Detection
spike = (Vol_current > 1.5 × Avg_Vol₂₀)
```

- 20-period rolling average via shift register + running sum
- `1/20` computed as reciprocal multiplication (`RECIP = 3277` in Q0.16)
- Avoids division entirely in hardware

## 🗂️ File Structure`
fpga-stock-signal/
│
├── src/
│   ├── stock_signal_top.v      # Top-level module
│   ├── shift_reg.v             # Parameterized shift register
│   ├── sma.v                   # Simple moving average
│   ├── ema.v                   # Exponential moving average
│   ├── rsi_calc.v              # RSI computation
│   ├── volume_filter.v         # Volume spike detection
│   └── signal_logic.v          # BUY/SELL/HOLD decision
│
├── tb/
│   └── tb_stock_signal.v       # Testbench
│
├── constraints/
│   └── zynq_constraints.xdc    # Pin mappings for Zynq board
│
└── README.md
```
##  Tools & Requirements

| Tool | Version | Purpose |
|---|---|---|
| Xilinx Vivado | 2020.x or later | Synthesis, simulation, bitstream |
| Vivado XSim | (bundled) | Behavioural simulation |
| Zynq FPGA Board | XC7Z020 (EDGE Zynq-7020) | Hardware target |
| Verilog HDL | IEEE 1364-2001 | RTL source language |

> **No physical board required for simulation.** The entire design can be verified using Vivado XSim without any hardware.
## 🚀 Getting Started
### Step 1 — Clone the Repository

```bash
git clone https://github.com/yourusername/fpga-stock-signal.git
cd fpga-stock-signal
```
### Step 2 — Open in Vivado

1. Open Xilinx Vivado
2. **Create Project** → RTL Project
3. Add all `.v` files from `src/` as **Design Sources**
4. Add `tb/tb_stock_signal.v` as a **Simulation Source**
5. Select target part: `xc7z020clg400-1` (or your board's part)

### Step 3 — Run Simulation

1. Flow Navigator → **Run Behavioral Simulation**
2. In the toolbar, click **Run All** (`>>`) — *not* "Run for 100ns"
3. Watch the Tcl console for output:

=== TEST START ===
--- Phase 1: Downtrend ---
Step  28 | signal=SELL | valid=1
--- Phase 2: Uptrend ---
Step  82 | signal=BUY  | valid=1
--- Phase 3: Downtrend ---
Step 138 | signal=SELL | valid=1
=== TEST END ===
```
4. In the waveform window, add these signals for visual verification:
   - `price_in` — input price
   - `ema14_out` — fast EMA
   - `ema50_out` — slow EMA
   - `signal_out` — BUY/SELL/HOLD (set radix to Binary)
   - `signal_valid` — output valid flag
   - `rsi_out` — RSI value

### Step 4 — Synthesize (Optional)


Flow Navigator → Run Synthesis → Run Implementation → Generate Bitstrem

Check the utilization report to confirm the design fits within resource limits.

---

## Simulation Results
The testbench runs three phases to validate the design:

| Phase | Price Trend | Expected Signal | When |
|---|---|---|---|
| Phase 1 | 200 → 100 (downtrend) | **SELL** | ~Step 25–30 |
| Phase 2 | 50 → 248 (strong uptrend) | **BUY** | ~Step 75–85 |
| Phase 3 | 200 → 150 (downtrend again) | **SELL** | ~Step 135–145 |
| Stable regions | Flat | **HOLD** | Throughout |

##  FPGA Resource Utilization (Zynq XC7Z020)
| Resource | Used | Available | Utilization |
|---|---|---|---|
| LUTs | ~800 | 85,000 | ~1% |
| Flip-Flops | ~400 | 106,400 | <1% |
| DSP Slices | ~8 | 220 | ~3.6% |
| Block RAM | ~4 tiles | 140 tiles | ~2.8% |
| I/O Pins | ~8 | 200 | ~4% |

The design uses less than **4% of available resources**, leaving significant headroom for extensions.
## ⚖️ Why FPGA Over Software?

| Parameter | Python/C++ | FPGA (This Project) |
|---|---|---|
| Latency | 50 µs – 500 µs | **10 – 20 ns** |
| Execution | Sequential | **Fully Parallel** |
| Determinism | Non-deterministic | **Deterministic** |
| OS Overhead | Present | **None** |
| Throughput | ~1M samples/sec | **100M samples/sec** |

For context: 10 ns is the time light travels ~3 metres. Software takes ~50,000× longer to make the same decision.

## 🔧 Fixed-Point Arithmetic (Q16.16 Format)

FPGAs have no native floating-point unit. This project uses **Q16.16 fixed-point representation**:
```
Real value × 65536 = Stored integer
Example: $142.75 × 65536 = 9,355,264  (stored as a 32-bit integer)
```
- Upper 16 bits = integer part
- Lower 16 bits = fractional part
- 64-bit intermediates used during multiplication to prevent overflow
- All constants (alpha, reciprocals, thresholds) pre-scaled at compile time

## 🐛 Known Issues Fixed During Development
| Bug | Root Cause | Fix Applied |
|---|---|---|
| Always HOLD output | `fast_above` was a registered signal (1-cycle lag) causing crossover detector to compare stale values | Made `fast_above` combinational (wire) |
| EMA cold-start error | EMA initialised to 0, spending 50+ cycles climbing to price range | Seeded EMA with first price sample |
| Volume spike never triggering | Threshold check was `vol > avg>>1` (0.5×) instead of 1.5× | Restored correct threshold wire |
| RSI always zero | 64-bit product bit-sliced incorrectly `[47:16]` | Fixed bit-select and intermediate widths |

## 🔮 Future Enhancements
- [ ] Deploy on Zynq board — verify LED outputs physically
- [ ] UART interface to feed real prices from PC in real time
- [ ] Add MACD and Bollinger Bands as additional indicators
- [ ] Multi-stock parallel processing (duplicate module blocks)
- [ ] 7-segment display to show live RSI values on board
- [ ] ASIC synthesis via Synopsys Design Compiler for gate-level analysis
- [ ] Integration with Python price feed via UART for live demo

## 🎓 Academic Context
- RTL design methodology in Verilog
- Fixed-point arithmetic for FPGA
- Hardware implementation of financial algorithms
- Modular testbench design and verification
- Pipeline architecture and parallel processing

> The design has been verified using Vivado XSim behavioural simulation. Physical board deployment is planned as a future extension.

## 📚 References
1. J. W. Wilder, *New Concepts in Technical Trading Systems*, Trend Research, 1978.
2. Intel (Altera), *FPGA-Based Algorithmic Trading*, Intel FPGA White Paper, 2019.
3. P. Chu, *FPGA Prototyping by Verilog Examples*, Wiley-IEEE Press, 2008.
4. Xilinx (AMD), *Vivado Design Suite User Guide*, UG901, 2022.
5. Optiver Trading, "How FPGAs Are Used in Trading", https://optiver.com

