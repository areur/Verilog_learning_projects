`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/17/2026 05:44:35 PM
// Design Name: 
// Module Name: top_tb
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
    reg tcarryIn, tsaturation;
    wire [7:0] tresult;
    wire [3:0] tstatusOut;
    wire overflow, carry_out, negative, zero;
    integer i,j;
    
    ALU testALU (
        .operand1(tIn1),
        .operand2(tIn2),
        .carryIn(tcarryIn),
        .saturationEna(tsaturation),
        .opSelect(tOp),
        .result(tresult),
        .statusOut(tstatusOut)
    );
    
    //Self-Checking variables
    reg [7:0] expectedResult;
    reg [3:0] expectedFlags;
    integer passCount, failCount; 
    reg [8*10-1:0] opName;
    
    reg [8:0] rawResult;
    wire signed [8:0] signed1 = $signed(tIn1);//implicitly sign-extend to 9 bits
    wire signed [8:0] signed2 = $signed(tIn2);
    
    //so you can read the flags easier
    assign overflow = tstatusOut[3];
    assign carry_out = tstatusOut[2];
    assign negative = tstatusOut[1];
    assign zero = tstatusOut[0];
    
    task self_check; 
        begin
            //Determine expected values                
            case (tOp)
                3'd0: begin 
                        rawResult = signed1 + signed2 + tcarryIn;
                        opName = "ADD";
                    end
                3'd1: begin
                        rawResult = signed1 - signed2;
                        opName = "SUB";
                    end
                3'd2: begin
                        rawResult = tIn1 & tIn2;
                        opName = "AND";
                      end  
                3'd3: begin 
                        rawResult = tIn1 | tIn2; 
                        opName = "OR";
                      end
                3'd4: begin
                        rawResult = tIn1 ^ tIn2;
                        opName = "XOR";
                      end
                3'd5: begin
                        rawResult = tIn1 << 1;
                        opName = "ShiftLeft";
                      end
                3'd6: begin
                        rawResult = tIn1 >> 1;
                        opName = "ShiftRight";
                      end
                3'd7: begin //SIGNED Compare
                        opName = "Compare";
                        if ($signed(tIn1) > $signed(tIn2)) 
                            rawResult = 8'd2;
                        else if ($signed(tIn1) < $signed(tIn2)) 
                            rawResult = 8'd1;                  
                        else 
                            rawResult = 8'd0; //equal
                      end
                default: rawResult = 8'd0;        
            endcase
            
            // Overflow & Carry Flags
            if (tOp == 3'd0) begin
                expectedFlags[3] = (tIn1[7] ~^ tIn2[7]) & (tIn1[7] ^ rawResult[7]);
                //(~^) XNOR to be true whenever they are the same
                //(^) XOR to be true whenever the signs of either operand (knowing they match) and the result are different
                expectedFlags[2] = rawResult[8];//Carry flag, taken from before saturation  
            end 
            else begin
                expectedFlags[3] = (tIn1[7] ^ tIn2[7]) & (tIn1[7] ^ rawResult[7]);
                //XOR to detect that the operands have different signs and the output sign differs from the first operand 
                //EXAMPLE: -127-(+126) = +1 is wrong, overflow must have occured 
                expectedFlags[2] = (signed1 < signed2);//Carry flag, checking if a borrow occured before saturation
            end
            
            
            //Saturating Arithmetic
            if (tOp == 3'd0 || tOp == 3'd1) begin
                if (tsaturation && expectedFlags[3]) begin//saturation on and overflow detected
                    expectedResult = rawResult;
                    if (rawResult[8]) //negative
                        expectedResult = -128;
                    else 
                        expectedResult = 127; 
                end
                else 
                    expectedResult = rawResult;
            end
            else begin
                expectedFlags[3] = 0;
                expectedFlags[2] = 0;
                expectedResult = rawResult;
            end
            expectedFlags[1] = expectedResult[7]; //Negative Flag
            expectedFlags[0] = (expectedResult == 0); //Zero Flag
                  
            //Run Self Check
            if ($signed(tresult) !== expectedResult) begin
                failCount = failCount + 1;
                $error("FAIL [%0d, %0s]: Input 1 = %0d, Input 2 = %0d | expected: %0d, got: %0d", 
                failCount, opName, tIn1, tIn2, expectedResult, tresult);
            end
            else if (tstatusOut !== expectedFlags) begin
                failCount = failCount + 1;
                $error("FAIL [%0d, %0s, FLAG MISMATCH]: Input 1 = %0d, Input 2 = %0d | expected: %4b, got: %4b", 
                failCount, opName, tIn1, tIn2, expectedFlags, tstatusOut);
            end
            else 
                passCount = passCount + 1;
        end  
    endtask
    
    initial begin
        //Randomized testing
        tcarryIn = 0;
        passCount = 0;
        failCount = 0;
        
        
        for (i = 0; i < 8; i = i + 1) begin
            //Apply Stimulus
            tOp = i;
            for (j = 0; j < 10; j = j + 1) begin
                //Random Stimulus
                if (j<5 && i<2)
                    tsaturation = 1;
                else 
                    tsaturation = 0;
                
                tIn1 = $urandom;
                tIn2 = $urandom;
                tcarryIn = $urandom % 2;
                
                #1; //mandatory delay to let values settle
                self_check();
                #4;
            end
            
        end
        
       
        
        //Corner-Case Testing
        tOp = 3'd0;
        tIn1 = 255;
        tIn2 = 255;

        #1; //mandatory delay to let values settle
        self_check();
        #4;
        
        //Test Summary
        $display("------------------------------------------");
        $display("Results: %0d passed, %0d failed / 81 total",
                  passCount, failCount);

        if (failCount > 0)
            $fatal(1, "TEST FAILED - %0d errors detected", failCount);
        else
            $display("TEST PASSED");
        $finish;
    end
endmodule