`timescale 1ns / 1ps

//IRQ flipflop
module FF(input set, input reset, output reg sigout = 1'b0);
	 
    always @(posedge set, posedge reset) begin
	     if(reset)
		      sigout <= 1'b0;		  
		  else
		      sigout <= 1'b1;	
	 end

endmodule
