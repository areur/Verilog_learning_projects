`timescale 1ns / 1ps

module uart_top #(
  parameter BITS_PER_WORD = 8,
  parameter CLOCK_RATE = 100_000_000,
  parameter PARITY = 2,
  parameter NUM_STOP_BITS = 2,
  parameter LOOPBACK = 1 //0 - tx output feeds to uart_txd pin, rx input feeds to uart_rxd pin
                         //1 - TX connects directly to RX
) (
    input wire clk,
    input wire rst,

    input wire [1:0] baud_sel,

    input wire [BITS_PER_WORD-1:0] tx_data,
    input wire tx_data_ready,
    //NOTE: Vivado (but primarily Verilog-2001) require a module output defined by a submodule to be "output wire"
    output wire tx_busy_flag,

    input wire rx_enable,
    output wire [BITS_PER_WORD-1:0] rx_data,
    output wire [1:0] rx_errors,
    output wire rx_data_ready,

    output wire uart_txd, //physical TX pin, holds the output coming out of TX
    input wire uart_rxd //physical RX pin, RX will read whatever comes to this pin
  );

  wire tx_tick, rx_tick;
  wire serial_data; //internal storage for the data coming out of the transmitter
  
  assign uart_txd = serial_data; //set TX output equal to the data coming out of the transmitter

  wire rx_input;
  assign rx_input = (LOOPBACK != 0) ? serial_data : uart_rxd;
    //if loopback is enabled, the RX will be fed the data coming out of TX (serial_data)
    //if loopback is not enabled the RX will be fed the data at the uart_rxd pin

  BaudGenerator #(
                  .CLOCK_RATE(CLOCK_RATE)
                ) BaudRateGenerator (
                  .clk(clk),
                  .rst(rst),
                  .baud_sel(baud_sel),
                  .tx_tick(tx_tick),
                  .rx_tick(rx_tick)
                );
  uart_tx #(
            .BITS_PER_WORD(BITS_PER_WORD),
            .PARITY(PARITY),
            .NUM_STOP_BITS(NUM_STOP_BITS)
          ) TX (
            .clk(clk),
            .rst(rst),
            .tx_tick(tx_tick),
            .in_parallel_Data(tx_data),
            .TX_VALID(tx_data_ready),
            .TX_ACTIVE(tx_busy_flag),
            .out_dataTX(serial_data)
          );

  uart_rx #(
            .BITS_PER_WORD(BITS_PER_WORD),
            .PARITY(PARITY),
            .NUM_STOP_BITS(NUM_STOP_BITS)
          ) RX (
            .clk(clk),
            .rst(rst),
            .rx_tick(rx_tick),
            .in_dataRX(rx_input),
            .RX_ENABLE(rx_enable),
            .out_parallelData(rx_data),
            .errors(rx_errors),
            .RX_VALID(rx_data_ready)
  );

endmodule

