`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/17/2026 03:32:00 PM
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

module top_tb();

    reg [7:0] tIn1, tIn2;
    reg [2:0] tOp;
    wire [7:0] tresult;
    wire tcarryOut;
    
    ALU testALU (
        .operand1(tIn1),
        .operand2(tIn2),
        .opSelect(tOp),
        .result(tresult),
        .carryOut(tcarryOut)
    );
    initial begin
        //Directed testing
        
        //Addition
        tOp = 3'd0;
        
        tIn1 = 5;
        tIn2 = 5;
        #5;
        
        tIn1 = 3;
        tIn2 = 7;
        #5;
        
        //Subtraction
        tOp = 3'd1;
        tIn1 = 7;
        tIn2 = 3;
        #5;
        
        tIn1 = 3;
        tIn2 = 7;
        #5;
        
        //Logic operations
        tIn1 = 8'b10110011;
        tIn2 = 8'b00110101;
        tOp = 3'd2;
        #2;
        tOp = 3'd3;
        #2;
        tOp = 3'd4;
        #2;
        
        //Shifts
        tOp = 3'd5;
        #2;
        tOp = 3'd6;
        #2;
        
        //Compare cases
        tOp = 3'd7;
        tIn1 = 3;
        tIn2 = 7;
        #5;
        
        tIn1 = 7;
        tIn2 = 3;
        #5;
        
        tIn1 = 3;
        tIn2 = 3;
        #5;
        
        //Corner-Case Testing
        tOp = 3'd0;
        tIn1 = 255;
        tIn2 = 255;
        #5;
        
        $finish;
    end
endmodule