# LF-SDR X1 Makefile
# Complete build system supporting full-system and subsystem builds.
# Uses Verilator for linting/simulation.
#
# FIX: Added 'top' and 'top-run' targets that use LF_TOP_TB.

# ============================================================
# Tool Configuration
# ============================================================
VERILATOR = verilator
VFLAGS    = --binary --trace-fst -Wno-fatal -I rtl -I rtl/packages -I rtl/interfaces -I rtl/common

# ============================================================
# File Lists
# ============================================================

# Common utilities
COMMON_SRCS = rtl/common/LF_FIFO.sv \
              rtl/common/LF_MUX.sv \
              rtl/common/LF_COUNTER.sv \
              rtl/common/LF_REGISTER.sv \
              rtl/common/LF_EDGE_DETECT.sv \
              rtl/common/LF_SYNC.sv \
              rtl/common/LF_CLOCK_ENABLE.sv \
              rtl/common/LF_RESET_SYNC.sv \
              rtl/common/LF_UTILS.sv

# Packages & Interfaces
PKG_SRCS = rtl/packages/LF_pkg.sv \
           rtl/interfaces/LF_cfg_if.sv \
           rtl/interfaces/LF_fifo_if.sv \
           rtl/interfaces/LF_stream_if.sv \
           rtl/interfaces/LF_status_if.sv \
           rtl/analytics/lf_perf_if.sv

# Transmitter
TX_SRCS = rtl/transmitter/LF_PKT_GEN.sv \
          rtl/transmitter/LF_CRC_GEN.sv \
          rtl/transmitter/LF_SCRAMBLER.sv \
          rtl/transmitter/LF_INTERLEAVER.sv \
          rtl/transmitter/LF_BPSK_MOD.sv \
          rtl/transmitter/LF_QPSK_MOD.sv \
          rtl/transmitter/LF_QAM16_MOD.sv \
          rtl/transmitter/LF_MOD_CTRL.sv \
          rtl/transmitter/LF_PILOT_INSERT.sv \
          rtl/transmitter/LF_S2P.sv \
          rtl/transmitter/LF_IFFT.sv \
          rtl/transmitter/LF_CP_INSERT.sv \
          rtl/transmitter/LF_TX_FIFO.sv

# Receiver
RX_SRCS = rtl/receiver/lf_rx_fifo.sv \
          rtl/receiver/lf_frame_detect.sv \
          rtl/receiver/lf_sync.sv \
          rtl/receiver/lf_cp_remove.sv \
          rtl/receiver/lf_fft.sv \
          rtl/receiver/lf_channel_est.sv \
          rtl/receiver/lf_equalizer.sv \
          rtl/receiver/lf_bpsk_demod.sv \
          rtl/receiver/lf_qpsk_demod.sv \
          rtl/receiver/lf_qam16_demod.sv \
          rtl/receiver/lf_demod_ctrl.sv \
          rtl/receiver/lf_p2s.sv \
          rtl/receiver/lf_deinterleaver.sv \
          rtl/receiver/lf_descrambler.sv \
          rtl/receiver/lf_crc_check.sv \
          rtl/receiver/lf_packet_decoder.sv

# Channel
CH_SRCS = rtl/channel/lf_delay.sv \
          rtl/channel/lf_awgn.sv \
          rtl/channel/lf_freq_offset.sv \
          rtl/channel/lf_clock_drift.sv \
          rtl/channel/lf_channel_top.sv

# Control
CTRL_SRCS = rtl/control/LF_CFG_REG.sv \
            rtl/control/LF_MAIN_CONTROLLER.sv \
            rtl/control/LF_PERF_MON.sv \
            rtl/control/LF_HEALTH_MON.sv \
            rtl/control/LF_LINK_ADAPT_CTRL.sv \
            rtl/control/LF_LINK_POWER_CTRL.sv \
            rtl/control/LF_STATUS_REG.sv

# Analytics
AN_SRCS = rtl/analytics/lf_ber_counter.sv \
          rtl/analytics/lf_latency_counter.sv \
          rtl/analytics/lf_packet_counter.sv \
          rtl/analytics/lf_snr_estimator.sv \
          rtl/analytics/lf_perf_mon.sv \
          rtl/analytics/lf_status_reg.sv

# Top
TOP_SRCS = rtl/top/LF_TOP.sv \
           rtl/top/LF_SYSTEM_BUS.sv \
           rtl/top/LF_INTERCONNECT.sv

# All RTL sources
ALL_SRCS = $(PKG_SRCS) $(COMMON_SRCS) $(TX_SRCS) $(RX_SRCS) $(CH_SRCS) $(CTRL_SRCS) $(AN_SRCS) $(TOP_SRCS)

# ============================================================
# Targets
# ============================================================

.PHONY: all compile run wave clean lint channel channel-run top top-run

# Full system build + run
all: top-run

# Compile full system with LF_TOP_TB
top:
	mkdir -p waves logs
	$(VERILATOR) $(VFLAGS) --top-module LF_TOP_TB -o lf_top_tb \
		$(ALL_SRCS) tb/LF_TOP_TB.sv 2>&1 | tee logs/top_compile.log

# Run full system
top-run: top
	./obj_dir/lf_top_tb

# Compile full system (top module, no TB)
compile:
	mkdir -p waves logs
	$(VERILATOR) $(VFLAGS) --top-module LF_TOP -o lf_top $(ALL_SRCS) 2>&1 | tee logs/compile.log

# Run full system (compile target)
run:
	./obj_dir/lf_top

# Channel-only build (original, working)
channel:
	mkdir -p waves logs
	$(VERILATOR) $(VFLAGS) --top-module tb_channel_top -o tb_channel_top \
		$(PKG_SRCS) $(COMMON_SRCS) $(CH_SRCS) tb/tb_channel_top.sv 2>&1 | tee logs/channel_compile.log

channel-run: channel
	./obj_dir/tb_channel_top

# Waveform viewer
wave:
	gtkwave waves/lf_top_tb.fst &

# Lint check only (no binary)
lint:
	$(VERILATOR) --lint-only -I rtl -I rtl/packages -I rtl/interfaces $(ALL_SRCS) 2>&1 | tee logs/lint.log

# Clean build artifacts
clean:
	rm -rf obj_dir waves/*.fst logs/* lf_top lf_top_tb tb_channel_top