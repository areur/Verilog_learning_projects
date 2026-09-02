`timescale 1ns / 1ps

module uart_rx #(
    parameter BITS_PER_WORD = 8,
    parameter PARITY = 2, //0 - Off, 1 - Odd Parity, 2 - Even Parity
    parameter NUM_STOP_BITS = 2
  ) (
    input wire clk,
    input wire rst,
    input rx_tick,
    input in_dataRX, //Single line of data being received
    input RX_ENABLE, //HIGH to turn the entire module on
    output reg [BITS_PER_WORD-1:0] out_parallelData,
    output reg [1:0] errors, //0 - Frame error, 1 - parity error
    output reg RX_VALID //HIGH when done reading data and can send it
  );

  //STATES
  localparam IDLE = 0;
  localparam START_BIT = 1;
  localparam RECEIVING_DATA_BITS = 2;
  localparam PARITY_BIT = 3;
  localparam STOP_BITS = 4;

  //TIMING
  localparam MAX_COUNT = (BITS_PER_WORD > NUM_STOP_BITS) ? BITS_PER_WORD : NUM_STOP_BITS;
  localparam widthReq = $clog2(MAX_COUNT);
  reg [3:0] stateCounter = 4'b0;
  reg [widthReq-1:0] bitsCounted = {widthReq{1'b0}};

  reg last_InValue = 1'b1;

  //STATE MACHINE VARS
  reg [2:0] currentState = IDLE;

  wire expectedParity = (PARITY == 2) ? ^out_parallelData : ~^out_parallelData;

  always @(posedge clk)
  begin
    if (rst)
    begin
      RX_VALID <= 0;
      errors <= 0;
      currentState <= IDLE;
      stateCounter <= 4'b0;
      bitsCounted <= {widthReq{1'b0}};
      last_InValue <= 1'b1;
      out_parallelData <= {BITS_PER_WORD{1'b0}};
    end
    else if (!RX_ENABLE) //turning off the RX will force it back to IDLE
    begin
      currentState <= IDLE;
      stateCounter <= 4'b0;
      bitsCounted <= {widthReq{1'b0}};
      last_InValue <= 1'b1;
    end

    else
    begin
      if (currentState == IDLE)
        last_InValue <= in_dataRX;
      if (last_InValue & ~in_dataRX) //negative edge detector: 1 --> 0
      begin
        currentState <= START_BIT;

        stateCounter <= 4'b0;
        bitsCounted <= {widthReq{1'b0}};

        errors <= 0;
        RX_VALID <= 0;
      end
      else if (rx_tick)
      begin
        begin
          //Theory: RX needs to find midpoint of each bit
          //rx_tick runs x16 faster than tx_tick,
          //so 8 counts of rx_tick is the midpoint
          case (currentState)
            //IDLE:
            START_BIT:
            begin
              if (stateCounter == 4'd7)
              begin //middle of bit, sample
                if (~in_dataRX)
                begin
                  //Valid start bit
                  out_parallelData <= 0;
                  currentState <= RECEIVING_DATA_BITS;
                end
                else
                begin //frame error
                  errors[0] <= 1'b1;
                  currentState <= IDLE;
                  out_parallelData <= {BITS_PER_WORD{1'b0}};
                  last_InValue <= 1'b1;
                end
                stateCounter <= 4'b0;
              end
              else
              begin
                stateCounter <= stateCounter + 4'b1;
              end
            end
            RECEIVING_DATA_BITS:
            begin
              if (stateCounter == 4'd15) //one complete bit cycle
              begin //middle of bit, sample
                //out_parallelData <= {out_parallelData[BITS_PER_WORD-1:1],in_dataRX};
                //data is sent LSB-->MSB (right to left)
                out_parallelData[bitsCounted] <= in_dataRX;

                stateCounter <= 4'b0;
                if (bitsCounted == BITS_PER_WORD-1)
                begin //done reading lets go
                  currentState <= PARITY ? PARITY_BIT : STOP_BITS;
                  bitsCounted <= {widthReq{1'b0}};
                end
                else
                begin
                  bitsCounted <= bitsCounted + 1'b1;
                end
              end
              else
              begin
                stateCounter <= stateCounter + 4'b1;
              end
            end
            PARITY_BIT:
            begin
              if (stateCounter == 4'd15)
              begin //middle of bit, sample
                if (in_dataRX != expectedParity)
                begin
                  errors[1] <= 1'b1;
                end
                stateCounter <= 4'b0;
                currentState <= STOP_BITS;
              end
              else
              begin
                stateCounter <= stateCounter + 4'b1;
              end
            end
            STOP_BITS:
            begin
              // if (bitsCounted == NUM_STOP_BITS-1)
              // begin //we're done here
              //   currentState <= IDLE;
              //   bitsCounted <= 0;
              //   RX_VALID <= 1;
              // end
              // else
              if (stateCounter == 4'd15)
              begin //middle of bit, sample
                if (in_dataRX)
                begin //stop bit received
                  if (bitsCounted == NUM_STOP_BITS-1)
                  begin
                    //bit found was the last stop bit
                    //we're done here
                    currentState <= IDLE;
                    stateCounter <= 4'b0;
                    bitsCounted <= {widthReq{1'b0}};
                    last_InValue = 1'b1;
                    RX_VALID <= 1'b1;
                  end
                  else
                    bitsCounted <= bitsCounted + 1'b1;
                end
                else
                begin //frame error, shouldn't be low if the transmission is over
                  errors[0] <= 1'b1;
                  stateCounter <= 4'b0;
                  bitsCounted <= {widthReq{1'b0}};
                  currentState <= IDLE;
                  last_InValue <= 1'b0;
                end
              end
              else
              begin
                stateCounter <= stateCounter + 4'b1;
              end
            end
            default:
            begin
              currentState <= IDLE;
              stateCounter <= 4'b0;
              bitsCounted <= {widthReq{1'b0}};
            end
          endcase
        end
      end
    end
  end
endmodule
