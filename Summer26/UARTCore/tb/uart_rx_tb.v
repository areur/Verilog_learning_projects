`timescale 1ns / 1ps

module uart_rx_tb();

  localparam BITS_PER_WORD = 8;
  localparam NUM_STOP_BITS = 2;

  reg tclk, trst, t_rx_tick, rx_input_data, t_rx_en;
  reg t_tx_tick; //rx needs to be x16 faster than tx so lets simulate the tx clock
  wire [BITS_PER_WORD-1:0] rx_output_data;
  wire [1:0] rx_flags;
  wire t_rx_valid;
  uart_rx #(
            .BITS_PER_WORD(BITS_PER_WORD),
            .PARITY(2), //0 - Off, 1 - Odd Parity, 2 - Even Parity
            .NUM_STOP_BITS(NUM_STOP_BITS)
          ) DUT (
            .clk(tclk), //General system clock
            .rst(trst),
            .rx_tick(t_rx_tick), //Clock Enable for when the Baud Generator ticks the system
            .in_dataRX(rx_input_data), //This is the single line of the data being received
            .RX_ENABLE(t_rx_en), //whether the rx is turned on or not

            .out_parallelData(rx_output_data), //Data that has been received
            .errors(rx_flags), //holds the presence of errors, 0 - frame error, 1 - parity error
            .RX_VALID(t_rx_valid) //HIGH when RX has complete valid data to read
          );

  //timing
  reg [2:0] tickCounter = 3'b0;
  reg [6:0] secondTickCounter = 7'b0;
  always #1
  begin
    if (trst)
    begin
      tclk = 1'b0;
      tickCounter = 3'b0;
      t_rx_tick = 1'b0;
    end
    else
    begin
      tclk = ~tclk;
      if (tclk)
        tickCounter = tickCounter + 3'b1;
      if (tickCounter >= 3'd1)
      begin
        t_rx_tick = 1'b1;
        tickCounter = 3'b0;
        secondTickCounter = secondTickCounter + 7'd1;
      end
      else
      begin
        t_rx_tick = 1'b0;
      end

      if (secondTickCounter >= 7'd16)
      begin
        t_tx_tick = 1'b1;
        secondTickCounter = 7'd0;
      end
      else
      begin
        t_tx_tick = 1'b0;
      end
    end
  end

  integer i,j;

  //added for readability
  reg [2:0] simulatedBitsPhase;
  initial
  begin
    $dumpfile("sim/sim.vcd");          // Specifies the VCD file path
    $dumpvars(0, uart_rx_tb); // Dumps all signals in this module and submodules

    tclk = 1'b0;
    trst = 1'b1;
    #5;
    trst = 1'b0;
    t_rx_en = 1'b1;

    for (i=0; i<5; i=i+1)
    begin
      $display("===== DATA TRANSMISSION #%0d =====",i);

      //start bit
      rx_input_data = 1'b0;
      simulatedBitsPhase = 3'd1;
      $display("start bit: %0b",rx_input_data);
      @(posedge t_tx_tick);


      //Data bits
      simulatedBitsPhase = 3'd2;
      for (j=0; j<BITS_PER_WORD; j=j+1)
      begin
        rx_input_data = $urandom;
        $display("Data bit %0d: %0b",j,rx_input_data);
        @(posedge t_tx_tick);
      end

      //parity, randomized values will test parity error flag
      rx_input_data = $urandom;
      simulatedBitsPhase = 3'd3;
      $display("Parity bit: %0b",rx_input_data);
      @(posedge t_tx_tick);

      //stop bits, randomized values will test framing error flag
      simulatedBitsPhase = 3'd4;
      for (j=0; j<NUM_STOP_BITS; j=j+1)
      begin
        rx_input_data = 1'b1;
        $display("Stop bit %0d: %0b",j,rx_input_data);
        @(posedge t_tx_tick);
      end

      repeat (2)
        @(posedge t_tx_tick);
    end
    $finish;
  end
endmodule
