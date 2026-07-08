`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/07/2026 08:45:11 PM
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


module top(
    input write_ena,
    input [1:0] write_addr,
    input [7:0] write_data,
    input [1:0] read_addr,
    output wire [7:0] read_data,
    output reg [7:0] counter,
    input clk,
    input rst
    );
    
    reg [7:0] register_array [3:0];
    
    //asynch read
    assign read_data = register_array[read_addr];
    
    
    always @ (posedge clk) begin
        if (rst) begin
            register_array[0] <= 0;
            register_array[1] <= 0;
            register_array[2] <= 0;
            register_array[3] <= 0;
            
            counter <= 8'd0;
        end
        else begin
            //iterate counter
            counter <= counter + 8'd1;
        
            //synch write
            if (write_ena) begin
                register_array[write_addr] <= write_data;
            end     
        end
    end
    
endmodule
