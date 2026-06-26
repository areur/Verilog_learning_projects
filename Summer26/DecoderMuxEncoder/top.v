`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/26/2026 04:56:39 PM
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

module decoder (
  input enable,
  input [1:0] select,
  output reg [3:0] out
);

    always @(*) begin
        if (~enable) begin
            case (select)
                2'd0: out =    4'b0001;
                2'd1: out =    4'b0010;
                2'd2: out =    4'b0100;
                2'd3: out =    4'b1000;
                default: out = 4'b0000;
            endcase
        end
    end
endmodule

module multiplexer (
    input enable,
    input [1:0] select,
    input [3:0] data,
    output reg out
);
    
    always @(*) begin 
        if (~enable) begin
            case (select)
                2'd0: out =    data[0];
                2'd1: out =    data[1];
                2'd2: out =    data[2];
                2'd3: out =    data[3];
                default: out = 1'b0;
            endcase
        end
    end    
endmodule

module priorityEncoder(
    input [3:0] data,
    output reg [1:0] out,
    output reg validity
);

    always @(*) begin
        validity = 1'b1;
        if (data[3]) 
            out = 2'b11;
        else if (data[2]) 
            out = 2'b10;
        else if (data[1]) 
            out = 2'b01;
        else if (data[0]) 
            out = 2'b00;
        else begin 
            out = 2'bXX;
            validity = 1'b0;
        end
    end   
endmodule

module top(
    input enable, //ACTIVE-LOW for both Decoder & MUX
    input [1:0] select, //Used for Decoder & MUX
    input [3:0] data_MUX, //data lines for MUX
    input [3:0] data_Enc, //Inputs for Priority Encoder
    
    output [3:0] decoderOut,
    output muxOut,
    output [1:0] encoderOut,
    output validity //low if any Priority Encoder value is on or smth
    );
    
    decoder dec (
        .enable(enable), 
        .select(select), 
        .out(decoderOut)
    );
    multiplexer mux (
        .enable(enable), 
        .select(select),
        .data(data_MUX), 
        .out(muxOut)
    );
    priorityEncoder priority (
        .data(data_Enc), 
        .out(encoderOut), 
        .validity(validity)
    );
    
endmodule
