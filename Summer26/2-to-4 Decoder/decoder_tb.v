`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/05/2026 03:16:18 PM
// Design Name: 
// Module Name: decoder_tb
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


module decoder_tb();
    reg ta,tb;
    wire [1:0] tOut;
    integer i;
    
    decoder testbench (.a(ta),.b(tb),.out(tOut));
   
    initial 
    begin
        for (i=0; i < 100; i = i + 1) 
        begin
            ta = $urandom % 2;
            tb = $urandom % 2;
            #10;
        end 
        $finish;
    end
endmodule
