`timescale 1ns / 1ps

module top_tb();
    reg tEnable;
    reg [1:0] tSelect;
    reg [3:0] tdata;
    
    wire [3:0] tdecoderOut;
    wire tMUXOut, tvalidity;
    wire [1:0] tencoderOut;
    
    top tb (
        .enable(tEnable), 
        .select(tSelect), 
        .data_MUX(tdata), 
        .data_Enc(tdata), 
        .decoderOut(tdecoderOut), 
        .muxOut(tMUXOut), 
        .encoderOut(tencoderOut), 
        .validity(tvalidity)
    );
    
    integer i,j;
    initial begin
        tEnable = 1'b0;
        for (i=0; i<100; i=i+1) begin
            tdata = $urandom & 4'b1111;
            for (j=0; j<4; j=j+1) begin
                tSelect = j;
                #5;
            end
            #5;
        end
    end
endmodule