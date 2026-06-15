`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/15/2026 04:14:48 PM
// Design Name: 
// Module Name: controller
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


module controller(
    output reg LED,
    input clk,
    input rst,
    input button
    );
    
    (* fsm_encoding = "one_hot", DONT_TOUCH = "yes" *) reg [2:0] currState = 3'b000;
    reg [2:0] nextState;
    reg [3:0] blinkCounter = 4'd0;
    
    localparam LED_OFF = 0;
    localparam LED_BLINK = 1;
    localparam LED_ON = 2;
    
    always @(posedge clk) begin
        //BLOCK 1: State Register w/ Clocked updates
        if (rst) begin
            currState <= LED_OFF;
        end
        else begin
            currState <= nextState;
        end
        
         //BLOCK 3: Output Logic
        case(currState)
            LED_OFF: 
            begin
                LED <= 1'b0;
                blinkCounter <= 4'd0;
            end
            
            LED_BLINK: 
            begin
                if (blinkCounter < 4'd15) begin
                    LED <= ~LED; 
                    blinkCounter <= blinkCounter + 1'd1;
                end
                else begin
                    blinkCounter <= 4'd0;
                end
            end
            
            LED_ON:
            begin
                LED <= 1'b1;
                blinkCounter <= 4'd0;
            end
            
            default:
            begin
                LED <= 1'b0;
                blinkCounter <= 4'd0;
            end
            
        endcase
    end

    always @(*) begin
        //BLOCK 2: Next-State Logic
        if (button) begin
            case(currState)
                LED_OFF: nextState = LED_BLINK;
                LED_BLINK: nextState = LED_ON;
                LED_ON: nextState = LED_OFF;
                default: nextState = LED_OFF;
            endcase
        end
        else begin
            nextState = currState;
        end
    end
endmodule
