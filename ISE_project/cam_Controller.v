`timescale 1ns / 1ps

module cam_Controller(
    input  pclk,
	 input  vsync,
	 input  href,
	 output reg [10:0]address = 0,
	 output reg dataInterrupt = 0,
	 output frameInterrupt
    );

    reg [10:0]pixelCounter = 0;
	 reg counterStart = 0;
	 reg thishref = 0;
	 reg lasthref = 0;

    assign frameInterrupt = vsync;

    always @(posedge pclk) begin
	     thishref <= href;			//Find posedge of href.
		  lasthref <= thishref;		//
		  dataInterrupt <= 0;
	 
	     if(href)
		      address <= address + 1;
		  if(vsync) //Should already be zero.
		      address <= 0;
				
		  if(thishref && !lasthref) begin
		      pixelCounter <= 0;
				counterStart <= 1;
		  end
		  
		  if(pixelCounter == 1560) begin
		      counterStart <= 0;
		  end
		  
		  if(counterStart)
		      pixelCounter <= pixelCounter + 1;
				
		  if(pixelCounter == 780 || pixelCounter == 1560)
		      dataInterrupt <= 1;
	 end

endmodule
