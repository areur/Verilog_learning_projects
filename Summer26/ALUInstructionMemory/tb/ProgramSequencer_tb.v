`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/14/2026 02:03 PM
// Design Name: 
// Module Name: ProgramSequencer_tb
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

module ProgramSequencer_tb();
    reg tclk, trst;
    reg tEnable;

    reg [7:0] tOp1, tOp2;

    wire [7:0] tResult;
    wire [3:0] tstatusOut;

    top DUT(
        .clk(tclk),
        .rst(trst),
        .readEnable(tEnable),
        .operand1(tOp1),
        .operand2(tOp2),
        .result(tResult),
        .statusOut(tstatusOut)
    );

    always #5 begin
        if (trst)
            tclk = 1'b0;
        else
            tclk = ~tclk;
    end   

    initial begin
        $dumpfile("sim/sim.vcd");          // Specifies the VCD file path
        $dumpvars(0, ProgramSequencer_tb); // Dumps all signals in this module and submodules
        tclk = 1'b0;
        trst = 1'b1;
        tEnable = 1'b1;
        tOp1 = 8'd5;
        tOp2 = 8'd5;
        #5
        trst = 1'b0;
        #500
        $finish;
    end
endmodule