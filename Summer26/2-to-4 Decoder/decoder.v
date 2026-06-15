`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/05/2026 03:16:18 PM
// Design Name: 
// Module Name: decoder
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


module decoder(
    input a,
    input b,
    output reg [1:0] out
    );
    
    always @(a,b) 
    begin
        case ({a,b})
            2'b00: out <= 2'd0;
            2'b01: out <= 2'd1;
            2'b10: out <= 2'd2;
            2'b11: out <= 2'd3;
            default: out <= 2'd0;
        endcase
    end
endmodule
