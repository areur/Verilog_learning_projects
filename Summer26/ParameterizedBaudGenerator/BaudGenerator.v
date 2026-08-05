`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/04/2026 07:06:15 PM
// Design Name: 
// Module Name: BaudGenerator
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module BaudGenerator#(
    parameter CLOCK_RATE = 10_000_000 //System internal clock rate
) (
        input clk,
        input rst,
        input [1:0] baud_sel,
        output reg tx_tick,
        output reg rx_tick
    );
    
    /*
    Take in the board's internal clock and outputs a tick clock-enable for rx (over-sampled by 16x), tx will divide down to get something at x1 speed 
    */
    
    //Calculate all divisors at synthesis time
    localparam DIV_9600 = (CLOCK_RATE / (9600 * 16)) - 1;
    localparam DIV_19200 = (CLOCK_RATE / (19200 * 16)) - 1;
    localparam DIV_115200 = (CLOCK_RATE / (115200 * 16)) - 1;
    
    //size counter to fit all divisors by sizing for the biggest one
    localparam rxCounterWidth = $clog2(DIV_9600 + 1);
    
    
    reg [rxCounterWidth-1:0] rxCounter;
    reg [rxCounterWidth-1:0] activeDivisor;
    reg [3:0] txScaledCounter;
    
    always @(*) begin
        case (baud_sel)
            2'b00: activeDivisor = DIV_9600[rxCounterWidth-1:0];//explicitly mentioning the bit width to avoid synthesis issues
            2'b01: activeDivisor = DIV_19200[rxCounterWidth-1:0];
            2'b10: activeDivisor = DIV_115200[rxCounterWidth-1:0];
            default: activeDivisor = DIV_9600[rxCounterWidth-1:0];
        endcase
    end
   
    
    always @(posedge clk) begin
        if (rst) begin
            rxCounter <= {rxCounterWidth{1'b0}};
            rx_tick <= 1'b0; 
        end
        else begin
            //create a 1-cycle enable pulse for rx
            if (rxCounter >= activeDivisor) begin //explicitly mentioning the bit width to avoid synthesis issues
                rxCounter <= {rxCounterWidth{1'b0}};
                rx_tick <= 1'b1;
            end
            else begin
                rxCounter <= rxCounter + 1;
                rx_tick <= 1'b0;
            end
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            txScaledCounter <= 4'd0;
            tx_tick <= 1'b0;
        end
        else begin
            tx_tick <= 1'b0;
            
            if (rx_tick) begin
                if (txScaledCounter == 4'd15) begin //16 rx ticks is 1 tx tick 
                    txScaledCounter <= 4'd0;
                    tx_tick <= 1'b1; 
                end
                else begin
                    txScaledCounter <= txScaledCounter + 1'b1;
                end
            end
        end
    end
endmodule
