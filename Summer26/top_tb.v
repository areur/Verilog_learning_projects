`timescale 1ns / 1ps

//FUTURE ADDITIONS: Overflow Handling
module top_tb();
    parameter TB_WIDTH = 4; //Only exists in testbench
    
    reg [(TB_WIDTH-1):0] ta, tb;
    reg tcin, tsub;
    wire [(TB_WIDTH-1):0] tsum;
    wire [TB_WIDTH:0] tcout;
    
    ripple_carry_adder #(.BUS_WIDTH(TB_WIDTH)) testbench (
        .a(ta),
        .b(tb),
        .cin(tcin),
        .sub(tsub),
        .sum(tsum),
        .last_cout(tcout)
    );
    
    integer i;
    initial begin
        tsub = 1'b0;
        tcin = 1'b0;
        for (i=0; i<50; i=i+1) begin
            ta = $urandom & {testbench.BUS_WIDTH{1'd1}};
            tb = $urandom & {testbench.BUS_WIDTH{1'd1}};
            #5;
        end
        tcin = 1'b1;
        for (i=0; i<50; i=i+1) begin
            ta = $urandom & {testbench.BUS_WIDTH{1'd1}};
            tb = $urandom & {testbench.BUS_WIDTH{1'd1}};
            #5;
        end
        tsub = 1'b1;
        tcin = 1'b0;
        for (i=0; i<50; i=i+1) begin
            ta = $urandom & {testbench.BUS_WIDTH{1'd1}};
            tb = $urandom & {testbench.BUS_WIDTH{1'd1}};
            #5;
        end
        tcin = 1'b1;
        for (i=0; i<50; i=i+1) begin
            ta = $urandom & {testbench.BUS_WIDTH{1'd1}};
            tb = $urandom & {testbench.BUS_WIDTH{1'd1}};
            #5;
        end
    end
endmodule