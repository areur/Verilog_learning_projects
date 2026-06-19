`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/17/2026 07:38:02 PM
// Design Name: 
// Module Name: LogicUnit
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


module LogicUnit #(parameter BUS_WIDTH = 32)(
    input [(BUS_WIDTH-1):0] a, 
    input [(BUS_WIDTH-1):0] b, 
    input [2:0] sel,
    output reg [(BUS_WIDTH-1):0] y
);
    
    always @(*) begin
        case (sel)
            3'd0: y = a&b; //AND
            3'd1: y = a|b; //OR
            3'd2: y = a^b; //XOR
            3'd3: y = ~(a&b); //NAND
            3'd4: y = ~(a|b); //NOR
            default: y = {BUS_WIDTH{1'd0}}; //zero, ext operation { will extend it to match the bus width
        endcase
    end
endmodule
