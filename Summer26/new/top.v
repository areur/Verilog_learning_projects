`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/08/2026 10:11:44 AM
// Design Name: 
// Module Name: top
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


module top(
    input ena, clk, rst, ok, cancel, quarterSensed,
    input [3:0] productPrice,
    output reg productDispenseSignal,
    output reg [3:0] quartersDispensed
    );
    
    localparam IDLE = 0;
    localparam MONEY_COLLECTION = 1;
    localparam ORDER_SUCCESS = 2;
    localparam REFUND = 3;
    
    reg [2:0] currState, nextState;
    reg [3:0] priceBuffer, quartersInserted, counter;
    
    wire okEvent, cancelEvent, sensorEvent;
    reg lastOkState, lastCancelState, lastSensorState;
    
    //POS-EDGE detection
    //Value is only 1 when the current value is 1 but the last value (from previous clock cycle) is not 1 
    assign okEvent = (ok & ~lastOkState);
    assign cancelEvent = (cancel & ~lastCancelState);
    assign sensorEvent = (quarterSensed & ~lastSensorState);
    
    always @(posedge clk) begin: transitionState
        if (rst) begin
            currState <= IDLE;
            
            lastOkState <= 0;
            lastCancelState <= 0;
            lastSensorState <= 0;
        end
        else begin
            currState <= nextState;
                        
            lastOkState <= ok;
            lastCancelState <= cancel;
            lastSensorState <= quarterSensed;
        end
    end
    
    always @ (*) begin: determineNextState //asynchronous, combinational
        nextState = currState; //fallback default for all cases
        //If this is not added, the synthesizer will add a latch
        case (currState)
            IDLE: begin
                //Wait for enable pulse
                if (ena) 
                    nextState = MONEY_COLLECTION;
            end
            MONEY_COLLECTION: begin
                //accepts quarters until the user hits ok
                //after hitting ok it compares the quarters inserted to the price
                    //enough quarters = Order_success
                    //insuffient quarters = return to this state and say something
                if (okEvent) begin
                    if (quartersInserted >= priceBuffer) 
                        nextState = ORDER_SUCCESS;
                    else
                        nextState = MONEY_COLLECTION;
                end
                else if (cancelEvent) begin
                    nextState = REFUND;
                end
            end
            ORDER_SUCCESS: begin
                if (counter >= 10) begin
                    nextState = IDLE;
                end
            end
            REFUND: begin
                if (counter >= 10) begin
                    nextState = IDLE;
                end
            end
            default: nextState = IDLE;
        endcase
    end
    
    always @(posedge clk) begin: determineOutput
        if (rst) begin
            priceBuffer <= 0;
            quartersInserted <= 4'b0;
            quartersDispensed <= 4'b0;
            productDispenseSignal <= 1'b0;
            counter <= 0;
        end
        else begin
        productDispenseSignal <= 1'b0;
            
            case (currState)
                IDLE: begin
                    //Wait for enable pulse
                    quartersInserted <= 3'b0;
                    if (ena)
                        priceBuffer <= productPrice; //moved here from determineNextState
                        //never access a reg from both a synchronous and asynchronous block
                end
                MONEY_COLLECTION: begin
                    //accepts quarters until the user hits ok
                    //after hitting ok it compares the quarters inserted to the price
                        //enough quarters = Order_success
                        //insuffient quarters = return to this state and say something
                    if (sensorEvent) begin
                        quartersInserted <= quartersInserted + 1;
                    end                 
                end
                ORDER_SUCCESS: begin
                    //dispenses product --> productDispenseSignal
                    //Calculates change and sends it --> quartersDispensed
                    //immediately returns to IDLE
                    productDispenseSignal <= 1'b1;
                    if (counter == 0) begin
                        quartersDispensed <= (quartersInserted-priceBuffer);
                        counter <= counter + 1;
                    end
                    else if (counter >= 10) begin
                        quartersDispensed <= 0;
                        counter <= 0;
                    end
                    else begin
                        counter <= counter + 1;
                    end
                end
                REFUND: begin
                    //Return all the quartersInserted
                    //immediately returns to IDLE
                    if (counter == 0) begin
                        quartersDispensed <= quartersInserted;
                        counter <= counter + 1;
                    end
                    else if (counter >= 10) begin
                        quartersDispensed <= 0;
                        counter <= 0;
                    end
                    else begin
                        counter <= counter + 1;
                    end
                end
            endcase
        end    
    end
endmodule
