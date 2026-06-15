`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/05/2026 02:54:09 PM
// Design Name: 
// Module Name: main
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


module main(
    input a,
    input b,
    input c,
    output wire d
    );
    
    wire wi_1;
    wire wi_2;
    wire wi_3;
    wire wi_11;
    
    assign wi_1 = a&c;
    assign wi_2 = (b|c);
    assign wi_3 = a&(~b);
    assign wi_11 = ~(wi_1|wi_2);
    
    assign d = wi_11 | wi_3;
endmodule
