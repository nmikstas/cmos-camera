`timescale 1ns / 1ps

module VGA(
    input clk25MHz,
	 
	 input [15:0]VGAData,
	 output reg [9:0]VGAAddress = 10'h000,
	 output VGAClk,
	 
	 output [15:0]vga,
	 
	 output reg hsync = 1'b1,
	 output reg vsync = 1'b1,
	 output reg frameInterrupt = 1'b0,
	 output reg dataInterrupt = 1'b0
    );

    //VGA to block RAM interface.
	 reg [9:0]VGAPixel = 10'h000;
	 reg [9:0]VGARow   = 10'h000;
	 
	 //Setup block RAM clock.
	 assign VGAClk = clk25MHz;
	 
	 always @(posedge clk25MHz) begin
	     frameInterrupt <= 1'b0;
		  dataInterrupt <= 1'b0;
        VGAPixel <= VGAPixel + 1;
		  
		  //Setup interrupts.
		  if(VGARow == 480 && !VGAPixel)
	         frameInterrupt <= 1'b1;
	     if(VGARow == 524 && VGAPixel == 399)
		      dataInterrupt <= 1'b1;
		  if(VGARow == 479 && !VGAPixel)
		      dataInterrupt <= 1'b1;
		  if(VGARow <= 478 && (!VGAPixel || VGAPixel == 399))
		      dataInterrupt <= 1'b1;		  
		  
		  if(VGAPixel == 799) begin						//Start new line.
		      VGAPixel <= 0;
				VGARow   <= VGARow + 1;
		  end
		  
		  if(VGARow == 524 && VGAPixel == 799) begin	//Start new frame.
		      VGAPixel <= 0;
				VGARow   <= 0;
		  end
		  
		  if(VGAPixel >= 656 && VGAPixel < 752)			//HSYNC.
		      hsync <= 0;
		  else
		      hsync <= 1;
				
		  if(VGAPixel == 799 && VGARow == 489)			//Start VSYNC.
		      vsync <= 1'b0;
				
		  if(VGAPixel == 799 && VGARow == 491)			//End VSYNC.
		      vsync <= 1'b1;
	 
		  if(VGARow < 480 && VGAPixel < 640) 			//Within visible range.
            VGAAddress <= VGAAddress + 1'b1;  
    end
	 
	 //Assign VGA output.
	 assign vga = (VGARow < 480 && VGAPixel > 0 && VGAPixel < 641) ? 
	              {VGAData[12], VGAData[11], VGAData[10], VGAData[9],
	 				   VGAData[8], VGAData[2], VGAData[1], VGAData[0],
					   VGAData[15], VGAData[14], VGAData[13], VGAData[7],
						VGAData[6], VGAData[5], VGAData[4], VGAData[3]} : 8'h00;
    //assign vga = (VGARow < 480 && VGAPixel > 0 && VGAPixel < 641) ? VGAData : 16'h0000;

endmodule
