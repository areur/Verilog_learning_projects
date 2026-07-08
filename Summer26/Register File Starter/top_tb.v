`timescale 1ns / 1ps
`define CLKcycle 2

module top_tb();
    reg [1:0] t_write_addr, t_read_addr;
    reg [7:0] t_write_data;
    wire [7:0] t_read_data, t_counter;
    reg t_write_ena, tclk, trst;
    
    top tb (
        .write_ena(t_write_ena),
        .write_addr(t_write_addr),
        .write_data(t_write_data),
        .read_addr(t_read_addr),
        .read_data(t_read_data),
        .counter(t_counter),
        .clk(tclk),
        .rst(trst)
    );

    always begin
        #(`CLKcycle/2)
        tclk <= (~tclk);
    end
    
    initial begin
        tclk = 1'b0;
        t_write_ena = 1'b0;
        trst = 0;
        
        $display ("Reg0: %b, Reg1: %b, Reg2: %b, Reg3: %b",
        tb.register_array[0],tb.register_array[1],tb.register_array[2],tb.register_array[3]);
        
        trst = 1;
        #((`CLKcycle)*2)
        trst = 0;
        
        //Write Data
        t_write_ena = 1'b1;
        t_write_addr = 2'b01;
        t_write_data = 8'hA;
        
        //Read it
        t_read_addr = 2'b01;
        #((`CLKcycle)*15)
        $finish;
    end
    
endmodule