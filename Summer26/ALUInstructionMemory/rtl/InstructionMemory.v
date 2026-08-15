`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/24/2026 04:47:29 PM
// Design Name: 
// Module Name: InstructionMemory
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

module rom #(
    parameter ADDR_WIDTH = 5, //5-bit address --> 32 locations
    parameter DATA_WIDTH = 16 // 16-bit data width
) (
    input wire clk,
    input wire read_en,
    input wire [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] data_out
);

    //Tell compiler this is Block ROM
    localparam ADDR_LOCATIONS = 1 << ADDR_WIDTH; // Shifts for every bit producing the correct power of two
    (* rom_style = "block" *) reg [DATA_WIDTH-1:0] memory [0:(ADDR_LOCATIONS)-1]; 
    
    //Init the ROM array from a file
    initial begin
        $display("Loading rom.");
        $readmemb("data/rom_init.mem",memory); //memb --> read binary
    end
    
    //synchronous read
    always @(posedge clk) begin 
        if (read_en)
            data_out <= memory[addr];
    end

endmodule

module ram #(//thought I needed to add Data Memory but opted to just use my inputs/outputs
    parameter ADDR_WIDTH = 5, //5-bit address --> 32 locations
    parameter DATA_WIDTH = 16 // 16-bit data width
) (
    input wire clk,
    input wire write_en,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);

    localparam ADDR_LOCATIONS = 1 << ADDR_WIDTH;                    // Shifts for every bit
    reg [DATA_WIDTH-1:0] memory [0:ADDR_LOCATIONS-1];               //producing the correct power of two
    
    //Init the ROM array from a file
    initial begin
        $display ("Loading ram.");
        $readmemb("data/ram_init.data",memory);
    end
    
    //synchronous read/write
    always @(posedge clk) begin 
        if (write_en) begin
            memory[addr] <= data_in;
        end
        else
            data_out <= memory[addr];
    end

endmodule

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
            //modified operand2 to be the shift amount
            3'd5: rawResult = operand1 << operand2; //Shift Left, Logical
            3'd6: rawResult = operand1 >> operand2;//Shift Right, Logical
            
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
            
            result = rawResult;
        end

        statusOut[1] = result[7]; //Negative Flag
        statusOut[0] = (result == 0); //Zero Flag
    end
endmodule

module top(
        input clk, rst,
        input readEnable,

        input [7:0] operand1, operand2,
        output reg [7:0] result,
        output reg [3:0] statusOut
    );

    //define program counter
    reg [4:0] programCounter = 5'h00; //ran up on my prices man i feel like uzi

    //fetch instruction
    wire [15:0] currentInstruction; //When the time is right the rom will send the selected instruction here

    //decode instruction
    wire [7:0] immediateOperand = currentInstruction[15:8];
    wire saturationEnabled = currentInstruction[6];
    wire carryIn = currentInstruction[5];
    wire [2:0] opcode = currentInstruction[4:2];
    wire [1:0] instructionClass = currentInstruction[1:0];

    wire [7:0] operandToUse = (instructionClass == 2'b01) ? immediateOperand : operand2;

    rom #(//ROM holding the list of instructions, externally loaded from a file
        .ADDR_WIDTH(5),
        .DATA_WIDTH(16)
    ) InstructionMemory (
        .clk(clk),
        .read_en(readEnable),
        .addr(programCounter),//always matches, so the wire always has the currentInstruction
        .data_out(currentInstruction)
    );

    ALU ALU(//performs arithmetic operations
        .operand1(operand1),// 8 bits
        .operand2(operandToUse),// 8 bits, set to operand 2 because commands like SUB, SHIFT, are impacted by the second operand more
        .opSelect(opcode), //3 bits
        .carryIn(carryIn), //1 bit
        .saturationEna(saturationEnabled), //1 bit
        .result(result),
        .statusOut(statusOut)
    );

    always @(posedge clk) begin //making the counter actually count
        if (rst)
            programCounter <= 5'h00;
        else
            if (programCounter < 5'h1F)
                programCounter <= programCounter + 1'b1;
            else
                programCounter <= 5'h00;
    end
endmodule

