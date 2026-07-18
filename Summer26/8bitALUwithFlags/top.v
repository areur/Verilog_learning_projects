`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/17/2026 05:44:35 PM
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
    input carryIn, saturationEna,
    output reg [7:0] result,
    output reg [3:0] statusOut
        //statusOut[3] --> Overflow flag
        //statusOut[2] --> Carry (out) flag
        //statusOut[1] --> Negative number flag
        //statusOut[0] --> Zero flag 
);
    
    reg [8:0] rawResult;
    wire signed [8:0] signed1 = $signed(operand1);//implicitly sign-extend to 9 bits
    wire signed [8:0] signed2 = $signed(operand2);
    always @(*) begin
        statusOut = 4'b0;
       
        //Perform Operation, create RAW result
        case (opSelect)
            3'd0: rawResult = signed1 + signed2 + carryIn;//ADD
            3'd1: rawResult = signed1 - signed2;//SUB
            3'd2: rawResult = operand1 & operand2;//AND
            3'd3: rawResult = operand1 | operand2;//OR
            3'd4: rawResult = operand1 ^ operand2;//XOR
            3'd5: rawResult = operand1 << 1; //Shift Left, Logical
            3'd6: rawResult = operand1 >> 1;//Shift Right, Logical
            3'd7: begin //SIGNED Compare
                    if ($signed(operand1) > $signed(operand2)) 
                        rawResult = 8'd2;
                    else if ($signed(operand1) < $signed(operand2)) 
                        rawResult = 8'd1;                  
                    else 
                        rawResult = 8'd0; //equal
                  end
            default: rawResult = 8'd0;        
        endcase
        
        // Overflow & Carry Flags
            if (opSelect == 3'd0) begin
                statusOut[3] = (operand1[7] ~^ operand2[7]) & (operand1[7] ^ rawResult[7]);
                //(~^) XNOR to be true whenever they are the same
                //(^) XOR to be true whenever the signs of either operand (knowing they match) and the result are different
                statusOut[2] = rawResult[8];//Carry flag, taken from before saturation  
            end 
            else begin
                statusOut[3] = (operand1[7] ^ operand2[7]) & (operand1[7] ^ rawResult[7]);
                //XOR to detect that the operands have different signs and the output sign differs from the first operand 
                //EXAMPLE: -127-(+126) = +1 is wrong, overflow must have occured 
                statusOut[2] = (signed1 < signed2);//Carry flag, checking if a borrow occured before saturation
            end
            
        //Saturating Arithmetic
        if (opSelect == 3'd0 || opSelect == 3'd1) begin
            if (saturationEna && statusOut[3]) begin//saturation on and overflow detected
                result = rawResult;
                if (rawResult[8]) //negative
                    result = -128;
                else 
                    result = 127; 
            end
            else 
                result = rawResult;
        end
        else begin //Clear carry and overflow if operation is not arithmetic
            statusOut[3] = 0;
            statusOut[2] = 0;
        end

        statusOut[1] = result[7]; //Negative Flag
        statusOut[0] = (result == 0); //Zero Flag
    end
endmodule