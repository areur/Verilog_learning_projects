`timescale 1ns / 1ps

module uart_overall_tb_claude();

  localparam BITS_PER_WORD = 8;
  localparam NUM_STOP_BITS = 2;
  localparam CLOCK_RATE    = 100_000_000;

  // 10 MHz -> 100 ns period -> 50 ns half period
  localparam real  CLK_PERIOD_NS = 1.0e9 / CLOCK_RATE;
  localparam       HALF_PERIOD   = CLK_PERIOD_NS / 2;

  reg  tclk, trst;
  reg  t_tx_ready, t_rx_on;
  reg  [1:0] t_baud_sel;
  wire t_tx_busy, t_rx_output_ready;
  reg  [BITS_PER_WORD-1:0] t_tx_data;
  wire [BITS_PER_WORD-1:0] t_rx_data;
  wire [1:0] t_rx_error_flags;
  wire t_txd;

  integer errcount = 0;
  integer i;

  uart_top #(
             .BITS_PER_WORD(BITS_PER_WORD),
             .CLOCK_RATE(CLOCK_RATE),
             .PARITY(2),
             .NUM_STOP_BITS(NUM_STOP_BITS),
             .LOOPBACK(1)
           ) DUT (
             .clk(tclk),
             .rst(trst),
             .baud_sel(t_baud_sel),
             .tx_data(t_tx_data),
             .tx_data_ready(t_tx_ready),
             .tx_busy_flag(t_tx_busy),
             .rx_enable(t_rx_on),
             .rx_data(t_rx_data),
             .rx_errors(t_rx_error_flags),
             .rx_data_ready(t_rx_output_ready),
             .uart_txd(t_txd),
             .uart_rxd(1'b1)
           );

  // ==================================================================
  // FIX #1 -- THIS IS THE ONE THAT KILLED THE COUNTERS.
  //
  // The original clock generator was:
  //     always #1 begin
  //       if (trst) tclk = 1'b0;   // <-- clock HELD LOW during reset
  //       else      tclk = ~tclk;
  //     end
  //
  // Every reset in this design is SYNCHRONOUS -- it only takes effect on a
  // posedge clk. Gating the clock off during reset means no posedge ever
  // happens while rst is high, so the reset branch never executes. rxCounter
  // and txScaledCounter therefore stayed at X for the entire simulation, and
  // "X + 1" is still X, so the counters never counted and rx_tick never fired.
  //
  // A clock must free-run. If you genuinely need a gated clock on hardware,
  // use the FPGA's clock-enable inputs (or a BUFGCE), never a behavioural
  // if-statement, and pair it with an asynchronous reset.
  //
  // FIX #2: the period was 2 ns = 500 MHz, while the design was parameterised
  // for CLOCK_RATE = 10 MHz. Every timing number in the old testbench was
  // therefore meaningless. The period is now derived from CLOCK_RATE.
  // ==================================================================
  initial tclk = 1'b0;
  always #(HALF_PERIOD) tclk = ~tclk;

  // Watchdog so a hang shows up as a failure instead of running forever
  initial begin
    #100_000_000;
    $display("[%0t] TIMEOUT -- simulation did not finish", $time);
    $fatal;
  end

  // ---- Send one byte and check what comes back through the loopback ----
  task send_and_check(input [BITS_PER_WORD-1:0] data);
    begin
      @(posedge tclk);
      t_tx_data  <= data;
      // FIX #3: a single-cycle pulse is now enough, because uart_tx latches the
      // request on the system clock instead of waiting for a tx_tick. The old
      // testbench pulsed for 5 ns and the TX simply never saw it.
      t_tx_ready <= 1'b1;
      @(posedge tclk);
      t_tx_ready <= 1'b0;

      @(posedge t_rx_output_ready);   // wait for a complete received word

      if (t_rx_data !== data) begin
        $display("[%0t] FAIL sent %02h, received %02h", $time, data, t_rx_data);
        errcount = errcount + 1;
      end
      else if (t_rx_error_flags !== 2'b00) begin
        $display("[%0t] FAIL sent %02h, flags = %b (frame/parity error)",
                 $time, data, t_rx_error_flags);
        errcount = errcount + 1;
      end
      else begin
        $display("[%0t] PASS %02h", $time, data);
      end
    end
  endtask

  // ---- Measure the real bit period on the tx_tick line ----
  task measure_baud(input [1:0] sel, input integer expected_baud);
    real t1, t2, measured, err_pct;
    begin
      t_baud_sel = sel;
      @(posedge DUT.tx_tick); t1 = $realtime;
      @(posedge DUT.tx_tick); t2 = $realtime;
      measured = 1.0e9 / (t2 - t1);              // ns -> Hz
      err_pct  = 100.0 * (measured - expected_baud) / expected_baud;
      $display("  baud_sel=%b  expected %7d  measured %9.1f  error %+6.2f %%",
               sel, expected_baud, measured, err_pct);
      // UART tolerates roughly +/-2 % end to end; flag anything worse
      if (err_pct > 2.0 || err_pct < -2.0) begin
        $display("    ^^ FAIL: baud error out of tolerance");
        errcount = errcount + 1;
      end
    end
  endtask

  initial
  begin
    $dumpfile("sim/sim.vcd");
    $dumpvars(0, uart_overall_tb_claude);

    t_rx_on    = 1'b1;
    t_tx_ready = 1'b0;
    t_tx_data  = 0;
    t_baud_sel = 2'b01;
    trst       = 1'b1;

    // FIX #4: hold reset for a few real clock cycles, with the clock running
    repeat (10) @(posedge tclk);
    trst = 1'b0;
    repeat (10) @(posedge tclk);

    $display("\n=== Baud generator accuracy (CLOCK_RATE = %0d Hz) ===", CLOCK_RATE);
    measure_baud(2'b00,   9600);
    measure_baud(2'b01,  19200);
    measure_baud(2'b10, 115200);
    measure_baud(2'b11,    900);   // this one was completely broken before

    $display("\n=== Loopback data test @ 19200 ===");
    t_baud_sel = 2'b01;
    repeat (4) @(posedge DUT.tx_tick);   // settle on the new rate

    // FIX #5: the old testbench spaced bytes #245 apart and stopped at 11.75 us.
    // One frame at 19200 baud takes 12 bits x 52 us = 625 us, so the original
    // run ended before even a single start bit had finished.
    send_and_check(8'hA5);
    send_and_check(8'h00);
    send_and_check(8'hFF);
    send_and_check(8'h5A);
    for (i = 0; i < 4; i = i + 1)
      send_and_check($random);

    $display("\n=== Loopback data test @ 900 (was broken by the width bug) ===");
    t_baud_sel = 2'b11;
    repeat (4) @(posedge DUT.tx_tick);
    send_and_check(8'h3C);

    $display("\n==================================");
    if (errcount == 0)
      $display("ALL TESTS PASSED");
    else
      $display("%0d FAILURE(S)", errcount);
    $display("==================================\n");
    $finish;
  end
endmodule
