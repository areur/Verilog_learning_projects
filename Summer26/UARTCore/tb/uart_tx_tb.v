`timescale 1ns / 1ps

module uart_tx_tb();

  localparam BITS_PER_WORD = 8;

  reg tclk, trst, t_tx_tick, t_tx_valid;
  reg [BITS_PER_WORD-1:0] tx_input_data;
  wire t_tx_on, tx_output_data;
  uart_tx #(
            .BAUD_RATE(9_600),
            .BITS_PER_WORD(BITS_PER_WORD),
            .PARITY(2), //0 - Off, 1 - Odd Parity, 2 - Even Parity
            .NUM_STOP_BITS(2)
          ) DUT (
            .clk(tclk), //General system clock
            .rst(trst),
            .tx_tick(t_tx_tick), //Clock Enable for when the Baud Generator ticks the system
            .in_parallel_Data(tx_input_data), //Data to be transmitted
            .TX_VALID(t_tx_valid), //HIGH when TX has new valid data to transmit
            .TX_ACTIVE(t_tx_on), //HIGH when TX is working
            .out_dataTX(tx_output_data) //This is the single line of the data being sent out
          );

  //timing
  reg [2:0] tickCounter = 3'b0;
  always #1
  begin
    if (trst)
    begin
      tclk = 1'b0;
      tickCounter = 3'b0;
      t_tx_tick = 1'b0;
    end
    else
    begin
      tclk = ~tclk;
      if (tclk)
        tickCounter = tickCounter + 3'b1;

      if (tickCounter >= 3'd2)
      begin
        t_tx_tick = 1'b1;
        tickCounter = 3'b0;
      end
      else
      begin
        t_tx_tick = 1'b0;
      end
    end
  end

  integer i;

  initial
  begin
    $dumpfile("sim/sim.vcd");          // Specifies the VCD file path
    $dumpvars(0, uart_tx_tb); // Dumps all signals in this module and submodules
    tclk = 1'b0;
    trst = 1'b1;
    #5;
    trst = 1'b0;

    for (i=0; i<5; i=i+1)
    begin
      tx_input_data = $urandom & {BITS_PER_WORD{1'd1}};
      t_tx_valid = 1'b1;
      #5
      t_tx_valid = 1'b0;
      #245;
    end
    $finish;
  end

endmodule
