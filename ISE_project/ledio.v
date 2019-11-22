`timescale 1ns / 1ps

module ledio(
    input clk,
    input reset,
    input write,
    input [15:0]id,
    input [15:0]din,
    output reg [7:0]ledsout = 8'h00
    );	 

    parameter LOAD_LEDS = 16'h002A;

    always @(posedge clk)
	     if(reset)
				    ledsout <= 8'h00;
					 
	     else begin	      		  
		      if(id == LOAD_LEDS && write)
				    ledsout <= din[7:0];								
		  end
endmodule
