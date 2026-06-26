`timescale 1ns / 1ps

module register_tb();
    reg [3:0] tx;
    wire [3:0] ty;
    reg tclk;
    integer i;
    
    register tb (.x(tx),.y(ty),.clk(tclk));
    
    always @(*)
    begin
        #5;
        tclk <= ~tclk; 
    end   
    
    initial
    begin
        tclk = 1'b0;
        
        for (i=0; i<100; i=i+1) 
        begin
            tx = $urandom % 8;
            #10;
        end 
        $finish;
    end
    
    
     
endmodule