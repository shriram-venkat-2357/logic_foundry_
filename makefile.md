# ============================================
# LF-SDR X1 — Member 3 Verification Makefile
# ============================================

TOP       = lf_top_tb
RTL_DIR   = rtl
CH_DIR    = channel
TB_DIR    = tb
OBJ_DIR   = obj_dir
WAVE_DIR  = waves
LOG_DIR   = logs

# All source files
SOURCES   = $(RTL_DIR)/lf_interfaces.sv \
            $(CH_DIR)/lf_delay.sv \
            $(CH_DIR)/lf_awgn.sv \
            $(CH_DIR)/lf_freq_offset.sv \
            $(CH_DIR)/lf_clock_drift.sv \
            $(CH_DIR)/lf_channel_top.sv \
            $(TB_DIR)/lf_driver.sv \
            $(TB_DIR)/lf_monitor.sv \
            $(TB_DIR)/lf_scoreboard.sv \
            $(TB_DIR)/lf_assertions.sv \
            $(TB_DIR)/lf_top_tb.sv

VFLAGS    = --binary --trace-fst -Wno-fatal \
            -I$(RTL_DIR) -I$(CH_DIR) -I$(TB_DIR) \
            --assert

.PHONY: all compile run wave clean regression

all: compile run

compile:
	@echo "🔨 Compiling all modules with Verilator..."
	@mkdir -p $(WAVE_DIR) $(LOG_DIR)
	verilator $(VFLAGS) -o $(TOP) $(SOURCES)

run: compile
	@echo "🚀 Running simulation..."
	./$(OBJ_DIR)/V$(TOP) 2>&1 | tee $(LOG_DIR)/sim_output.log

wave:
	@echo "🌊 Opening GTKWave..."
	gtkwave $(WAVE_DIR)/lf_top_tb.fst &

regression: compile
	@echo "📊 Running BER regression..."
	python3 scripts/ber_regression.py

clean:
	rm -rf $(OBJ_DIR) $(WAVE_DIR)/*.fst $(WAVE_DIR)/*.png $(LOG_DIR)/*
