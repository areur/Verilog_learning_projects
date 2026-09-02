`timescale 1ns / 1ps

module uart_tx #(
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
  localparam MAX_COUNT = (BITS_PER_WORD > NUM_STOP_BITS) ? BITS_PER_WORD : NUM_STOP_BITS;
  localparam counterWidth = $clog2(MAX_COUNT);
  reg [counterWidth-1:0] stateCounter = {MAX_COUNT{1'b0}};

  //STATE MACHINE VARS
  reg [2:0] currentState = IDLE;
  reg [BITS_PER_WORD-1:0] currentData_latch = {BITS_PER_WORD{1'b0}};

  //Sticky Request Latch
  //At large baud rates, the FSM only ends up reading TX_VALID after a significant number of clock cycles
  //However outside modules will usually not hold TX_VALID high that long
  //So this latch goes high when TX_VALID does but cannot be read, then releases it when the transmitter can use it
  reg tx_request = 1'b0;
  reg [BITS_PER_WORD-1:0] tx_request_data = {BITS_PER_WORD{1'b0}};

  always @(posedge clk) begin
    if (rst) begin
      tx_request <= 1'b0;
      tx_request_data <= {BITS_PER_WORD{1'b0}};
    end    
    else if (TX_VALID && !tx_request && TX_ACTIVE) begin //store new request
      tx_request <= 1'b1;
      tx_request_data <= in_parallel_Data; //freezeframe data from the time it was requested
    end
    else if (tx_tick && (currentState == IDLE) && tx_request) begin
      tx_request <= 1'b0; // FSM will use up the request within this tick
    end
  end

  always @(posedge clk)
  begin: stateMachine //FSM --> Finite State Machine
    if (rst)
    begin
      TX_ACTIVE <= 0;
      out_dataTX <= 1'b1;
      currentState <= IDLE;
      stateCounter <= {counterWidth{1'b0}};
      currentData_latch <= {BITS_PER_WORD{1'b0}};
    end
    else if (tx_tick)
    begin
      case (currentState)
        IDLE:
        begin
          out_dataTX <= 1'b1; //manually hold high, ensuring line appears "inactive"
          if (TX_VALID) begin
            currentState <= START_BIT;
            TX_ACTIVE <= 1'b1;

            //latch data to work on right now
            currentData_latch <= (tx_request == 1'b1) ? tx_request_data : in_parallel_Data;
          end
          else begin
            TX_ACTIVE <= 0;
            stateCounter <= {counterWidth{1'b0}};
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
            currentState <= (PARITY != 0) ? PARITY_BIT : STOP_BITS; //usually verilog reads parity = 0 as false but ima just do it explicitly
            stateCounter <= {counterWidth{1'b0}};
          end
          else begin
            stateCounter <= stateCounter + 3'b1;
          end
        end
        PARITY_BIT: 
        begin
          out_dataTX <= (PARITY == 2) ? ^currentData_latch : ~^currentData_latch;
          //If true: Even parity (first value), if false: Odd parity (second value)

          stateCounter <= {counterWidth{1'b0}};
          currentState <= STOP_BITS;
        end
        STOP_BITS:
        begin
          //start or continue stop bits
          out_dataTX <= 1'b1; //in the situation that there is only 1 stop bit,
                           //driving this at the start prevents the stop bit
                           //from being lost completely
          if (stateCounter == NUM_STOP_BITS - 1) begin
            //end stop bits
            stateCounter <= {counterWidth{1'b0}};

            TX_ACTIVE <= 0;
            currentState <= IDLE;
            currentData_latch <= {BITS_PER_WORD{1'b0}};
          end
          else begin
            stateCounter <= stateCounter + 1'b1;
          end
        end
        default: 
        begin
          currentState <= IDLE;
          out_dataTX <= 1'b1;
          TX_ACTIVE <= 1'b0;  
        end  
      endcase
    end
  end

endmodule
