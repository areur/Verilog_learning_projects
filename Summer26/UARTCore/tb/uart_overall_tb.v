`timescale 1ns / 1ps

module uart_overall_tb();

  localparam BITS_PER_WORD = 8;
  localparam NUM_STOP_BITS = 2;
  localparam CLOCK_RATE = 1_000_000;

  reg tclk = 0; 
  reg trst = 0;

  reg [1:0] t_baud_sel = 2'b10;

  reg t_tx_ready, t_rx_on;
  wire t_tx_busy, t_rx_output_ready;
  reg [BITS_PER_WORD-1:0] t_tx_data;

  wire [BITS_PER_WORD-1:0] t_rx_data;
  wire [1:0] t_rx_error_flags;

  wire t_txd;
  reg t_rxd;

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
             .uart_rxd(t_rxd)
           );

  //timing
  always #1
  //important lesson: clocks must FREE-RUN
  //Beforehand I had a "if" block for when rst was high to start the clock
  //this caused the clock to be stuck at 0 when rst was high
  /*
  this meant all other "if (rst)" blocks in the rest of the code never started
  because they were in a "posedge clk" block. Theres no posedge if its always 0!!
  */
  begin
      tclk = ~tclk;
  end

  integer i;

  initial
  begin
    $dumpfile("sim/sim.vcd");          // Specifies the VCD file path
    $dumpvars(0, uart_overall_tb); // Dumps all signals in this module and submodules

    t_rx_on = 1;
    t_tx_ready = 1;
    t_rxd = 0; //unused but i dont want to leave any high-impedance nets

    tclk = 0;
    trst = 1; 
    #100;
    trst = 0;

    for (i=0; i<5; i=i+1)
    begin
      t_tx_data = $urandom & {BITS_PER_WORD{1'd1}};
      t_tx_ready = 1'b1;
      wait(t_tx_busy == 1'b1); //main bug was that this value was not held long enough for tx_tick to activate, now held dynamically
      t_tx_ready = 1'b0;
      #200;
    end
    #500;
    $finish;
  end
endmodule
