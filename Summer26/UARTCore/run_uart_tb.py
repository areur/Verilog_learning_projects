# run_uart_tb.py
import os
import sys
from glob import glob
from cocotb_tools.runner import get_runner

def test_uart_runner():
    sim = os.getenv("SIM", "icarus")
    runner = get_runner(sim)

    # Gather all RTL source files automatically
    rtl_sources = glob("rtl/*.v")

    # Add tb folder to Python module search path
    tb_path = os.path.abspath("tb")
    if tb_path not in sys.path:
        sys.path.insert(0, tb_path)

    # Compile RTL --> iverilog
    runner.build(
        sources=rtl_sources,
        hdl_toplevel="uart_top",   # Top module name inside rtl/uart_top.v
        always=True,
        build_dir="sim",            # Sets directory for sim files
        build_args=["-g2012"],      # Enable SystemVerilog/Verilog-2012 flags
        waves=True # Enables support for waveform gen
    )

    # Run Cocotb test --> vvp
    runner.test(
        hdl_toplevel="uart_top",
        test_module="uart_testcases", # Points to tb/test_uart_overall.py
        build_dir="sim",            # Sets directory for sim files
        test_dir="tb", # Sets working execution directory
        waves=True # Tells simulator to dump waveforms so I can use GTKWave
        # test_args=[""]
    )

if __name__ == "__main__":
    test_uart_runner()