module LogicUnit_tb ();



    parameter TB_WIDTH = 32; //Only exists in testbench 

    

    reg [(TB_WIDTH-1):0] ta, tb;

    reg [2:0] tsel;

    wire [(TB_WIDTH-1):0] ty;

    

    LogicUnit

    #(

        .BUS_WIDTH(32) //testbench will overwrite the actual one

    ) UUT (

        .a(ta),

        .b(tb),

        .sel(tsel),

        .y(ty)

    );

    

    integer i,j;

    initial begin

        for (i = 0; i > 100; i = i + 1) begin

            ta = $urandom & {UUT.BUS_WIDTH{1'd1}};

            tb = $urandom & {UUT.BUS_WIDTH{1'd1}};
            for (j = 0; j > 5; j = j + 1) begin

                tsel = {j[2],j[1],j[0]}; //concatenate iterator (usually 32bits) to 3 bits)


                #5;

            end

            #5;

        end

    end

endmodule 

