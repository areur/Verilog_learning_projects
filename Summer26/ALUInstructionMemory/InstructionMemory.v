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


module InstructionMemory(

    );
endmodule

module rom #(
    parameter ADDR_WIDTH = 5, //5-bit address --> 32 locations
    parameter DATA_WIDTH = 16 // 16-bit data width
) (
    input wire clk,
    input wire en,
    input wire [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] data_out
);

    //Tell compiler this is Block RAM
    (* rom_style = "block" *) reg [DATA_WIDTH-1:0] memory [0:(1<<ADDR_WIDTH)-1];
    
    //Init the ROM array from a file
    initial begin
        $display ("Loading rom.");
        $readmemh("rom_init.mem",memory);
    end
    
    //synchronous read
    always @(posedge clk) begin 
        if (en) begin
            data_out <= memory[addr];
        end
    end

endmodule
