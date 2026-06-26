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


module main_tb();
    reg ta,tb,tc;
    wire td;
    integer i;
    
    main testbench (ta,tb,tc,td);
    
    initial
    begin
        for (i=0; i < 100; i = i + 1) 
        begin
            ta = $urandom % 2;
            tb = $urandom % 2;
            tc = $urandom % 2;
            #5;
        end
        #10;
        $finish;
    end
endmodule