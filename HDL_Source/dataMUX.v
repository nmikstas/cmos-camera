`timescale 1ns / 1ps

module dataMUX(
    input  read,     
    input  [15:0]id,
     input  [15:0]i2cdata,
     input  [15:0]i2cstatus,
     input  [15:0]uartdata,
     input  [15:0]txcount,
     input  [15:0]rxcount,
     input  [15:0]busy,
     input  [15:0]sync,
    output [15:0]dout
    );

    assign dout = (id == 16'h0001 && read) ? i2cdata        :
                  (id == 16'h0002 && read) ? i2cstatus      :
                        (id == 16'h0003 && read) ? uartdata :
                        (id == 16'h0004 && read) ? txcount  :
                        (id == 16'h0005 && read) ? rxcount  :
                        (id == 16'h0008 && read) ? busy     :
                        (id == 16'h0009 && read) ? sync     :
                   16'h0000;
endmodule
