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

module ALU (
    input [7:0] operand1, operand2,
    input [2:0] opSelect,
    output reg [7:0] result,
    output reg carryOut
);
    
    always @(*) begin
        carryOut = 1'b0;
        
        case (opSelect)
            3'd0: {carryOut,result} = operand1 + operand2;//ADD
            3'd1: {carryOut,result} = operand1 - operand2;//SUB
            3'd2: result = operand1 & operand2;//AND
            3'd3: result = operand1 | operand2;//OR
            3'd4: result = operand1 ^ operand2;//XOR
            3'd5: result = operand1 << 1; //Shift Left
            3'd6: result = operand1 >> 1;//Shift Right
            3'd7: begin //Compare
                    if (operand1 > operand2) 
                        result = 8'd2;
                    else if (operand1 < operand2) 
                        result = 8'd1;                  
                    else 
                        result = 8'd0; //equal
                  end
            default: result = 8'd0;        
        endcase
    end
endmodule