`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/16/2026 06:32:00 PM
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
module half_adder(
	input a,b,
	output cout, sum
);
	assign sum = a^b;
    assign cout = a&b; 
endmodule

module full_adder( 
    input a, b, cin, sub,
    output cout, sum);
    wire cout1,sum1,cout2, filteredB;
    assign filteredB = b^sub;
	half_adder ha1 (.a(a),.b(filteredB),.cout(cout1),.sum(sum1)); 
	half_adder ha2 (.a(sum1),.b(cin),.cout(cout2),.sum(sum)); 
	
	assign cout = cout1 | cout2;
endmodule

module ripple_carry_adder #(parameter BUS_WIDTH = 32)(
    input [(BUS_WIDTH-1):0] a, b,
    input cin, sub,
    output wire [(BUS_WIDTH-1):0] sum, 
    output wire [BUS_WIDTH:0] last_cout
    );
    
    wire [BUS_WIDTH:0] carry;
    assign carry[0] = cin;
    
    genvar n;
    
    generate 
        for (n=0; n<BUS_WIDTH; n=n+1) begin
            full_adder fa(
                .a(a[n]),
                .b(b[n]),
                .cin(carry[n]),
                .sub(sub),
                .cout(carry[n+1]),
                .sum(sum[n])
            );
        end
    endgenerate
    
    assign last_cout = {carry[BUS_WIDTH], {(BUS_WIDTH){1'b0}} }; //cout becomes the last carry
    
endmodule
