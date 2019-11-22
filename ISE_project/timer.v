`timescale 1ns / 1ps

module timer(input clk, input write, input [15:0] id, input [15:0] din,
             input reset, output reg dout = 1'b0);

    parameter LOWER_TIMER = 16'h0010;
	 parameter UPPER_TIMER = 16'h0011;

    reg [31:0]timerreg = 32'h00000000;

    always @(posedge clk) begin
	     dout <= 1'b0;
		  
		  //Synchronous reset.   
        if(reset)
            timerreg <= 32'h00000000;
		  
		  else begin
		      //Load timer bits.
		      if(id == LOWER_TIMER && write)
                timerreg[15:0] <= din[15:0];
				
            if(id == UPPER_TIMER && write)
		          timerreg[31:16] <= din[15:0];
				
            //Decrement timer if not 0.
            if(timerreg[31:0] > 32'h00000001)			
                timerreg <= timerreg - 1'b1;
				
            //Timer is about to expire, send output strobe.
            if(timerreg[31:0] == 32'h00000001) begin
                timerreg <= timerreg - 1'b1;
				    dout <= 1'b1;
            end
        end
        					 
    end

endmodule
