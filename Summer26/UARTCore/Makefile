# VARIABLES
TB_CHOICE := tb/uart_overall_tb.v
# List of source files
ALL_RTL := $(wildcard rtl/*.v)
#	variable to open gtkwave file or na
WAVES ?= 1

.PHONY: lint simulate simulate-v simulate-coco help
# -tnull --> do compilation checks without making a .out or .vvp
# -g2012 --> SysVerilog/Verilog-2012 feature parsing
lint: 
	iverilog -g2012 -o sim/sim.out -tnull $(ALL_RTL) 

simulate: 
	@$(MAKE) simulate-v

simulate-v:
	@echo "Running Verilog Testbench"
	iverilog -g2012 -o sim/sim.out $(ALL_RTL) $(TB_CHOICE)
	vvp sim/sim.out
	@WAVE_FILE=$$(find sim/ -maxdepth 1 \( -name "*.fst" -o -name "*.vcd" \) | head -n 1); \
	if [ "$(WAVES)" = "1" ]; then \
		if [ -n "$$WAVE_FILE" ] && [ -f "$$WAVE_FILE" ]; then \
			echo "Opening $$WAVE_FILE in GTKWave..."; \
			gtkwave "$$WAVE_FILE"; \
		else \
			echo "Error: No .fst or .vcd file was created in sim/"; \
		fi; \
	else \
		echo "no waves"; \
	fi

simulate-coco:
	@echo "Running Cocotb Testbench..."
	python run_uart_tb.py
	@WAVE_FILE=$$(find sim/ -maxdepth 1 \( -name "*.fst" -o -name "*.vcd" \) | head -n 1); \
	if [ "$(WAVES)" = "1" ]; then \
		if [ -n "$$WAVE_FILE" ] && [ -f "$$WAVE_FILE" ]; then \
			echo "Opening $$WAVE_FILE in GTKWave..."; \
			gtkwave "$$WAVE_FILE"; \
		else \
			echo "Error: No .fst or .vcd file was created in sim/"; \
		fi; \
	else \
		echo "no waves"; \
	fi

help:
	@echo "lint: 			Runs iverilog linting on ur code"
	@echo "simulate-v [WAVES=1]: 	Runs a simulation w/ vvp and opens gtkwave if WAVES "
	@echo "simulate-coco [WAVES=1]: Runs a simulation w/ cocotb and opens gtkwave if WAVES"