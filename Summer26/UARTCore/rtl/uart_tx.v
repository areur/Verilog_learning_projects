`timescale 1ns / 1ps

module uart_tx #(
    parameter BAUD_RATE = 9_600,
    parameter BITS_PER_WORD = 8,
    parameter PARITY = 2, //0 - Off, 1 - Odd Parity, 2 - Even Parity
    parameter NUM_STOP_BITS = 2
  ) (
    input wire clk, //General system clock
    input wire rst,
    input wire tx_tick, //Clock Enable for when the Baud Generator ticks the system
    input wire [BITS_PER_WORD-1:0] in_parallel_Data, //Data to be transmitted
    input wire TX_VALID, //HIGH when TX has new valid data to transmit
    output reg TX_ACTIVE, //HIGH when TX is working
    output reg out_dataTX //This is the single line of the data being sent out
    
  );

  //STATES
  localparam IDLE = 0;
  localparam START_BIT = 1;
  localparam SENDING_DATA_BITS = 2;
  localparam PARITY_BIT = 3;
  localparam STOP_BITS = 4;

  //TIMING
  reg [3:0] stateCounter = 3'b0;

  //STATE MACHINE VARS
  reg [2:0] currentState = IDLE;

  reg [BITS_PER_WORD-1:0] currentData_latch;

  always @(posedge clk)
  begin: stateMachine
    if (rst)
    begin
      TX_ACTIVE <= 0;
    end
    else if (tx_tick)
    begin
      case (currentState)
        IDLE:
        begin
          if (TX_VALID) begin
            currentState <= START_BIT;
            TX_ACTIVE <= 1'b1;

            //latch data to work on right now
            currentData_latch <= in_parallel_Data;
          end
          else begin
            TX_ACTIVE <= 0;
            stateCounter <= 0;
            out_dataTX <= 1;
          end
        end
        START_BIT:
        begin
          //start the start bit and continue to next state
          out_dataTX <= 0;
          currentState <= SENDING_DATA_BITS;
        end
        SENDING_DATA_BITS:
        begin
          //send data using array position, starts with LSB (right-most)
          out_dataTX <= currentData_latch[stateCounter];

          //keep track of how many bits have been sent out
          if (stateCounter == BITS_PER_WORD-1) begin
            //done transmitting, move on to next state
            currentState <= PARITY ? PARITY_BIT : STOP_BITS;
            stateCounter <= 0;
          end
          else begin
            stateCounter <= stateCounter + 3'b1;
          end
        end
        PARITY_BIT: 
        begin
          out_dataTX <= (PARITY == 2) ? ^currentData_latch : ~^currentData_latch;
          //If true: Even parity (first value), if false: Odd parity (second value)

          stateCounter <= 0;
          currentState <= STOP_BITS;
        end
        STOP_BITS:
        begin
          //start or continue stop bits
          out_dataTX <= 1; //in the situation that there is only 1 stop bit,
                           //driving this at the start prevents the stop bit
                           //from being lost completely
          if (stateCounter == NUM_STOP_BITS - 1) begin
            //end stop bits
            stateCounter <= 0;

            TX_ACTIVE <= 0;
            currentState <= IDLE;
            currentData_latch <= 0;
          end
          else begin
            stateCounter <= stateCounter + 1;
          end
        end
        endcase
    end
  end

endmodule
