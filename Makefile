SOURCES = channel/lf_delay.sv channel/lf_awgn.sv channel/lf_freq_offset.sv channel/lf_clock_drift.sv channel/lf_channel_top.sv tb/tb_channel_top.sv
VFLAGS = --binary --trace-fst -Wno-fatal

all: compile run

compile:
	mkdir -p waves logs
	verilator $(VFLAGS) --top-module tb_channel_top -o tb_channel_top $(SOURCES)

run:
	./obj_dir/tb_channel_top

wave:
	gtkwave waves/tb_channel_top.fst &

clean:
	rm -rf obj_dir waves/*.fst logs/* tb_channel_top
