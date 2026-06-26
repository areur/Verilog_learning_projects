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

module controller_tb();
    wire tLED;
    reg tclk, trst, tbutton;
    integer i;
    
    controller tb(.LED(tLED), .clk(tclk), .rst(trst), .button(tbutton));
    
    always @(*)
    begin
        #5;
        tclk <= ~tclk; 
    end   
    
    initial begin
        tclk = 1'b0;
        trst = 1'b1;
        #10
        trst = 1'b0;
        
        $monitor("currState:%0b | nextState: %0b | LED: %0d",tb.currState,tb.nextState,tLED);
        
        for (i = 0; i < 100; i = i+ 1'd1) begin
            #20
            tbutton = 1'b1;
            #5
            tbutton = 1'b0;
        end
    end

endmodule