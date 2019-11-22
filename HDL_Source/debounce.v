`timescale 1ns / 1ps

module debounce(
    input clk,
    input  [3:0]in_button,
    output reg [3:0]out_button = 4'h0
    );

    //16ms button bebounce counters.  1 for each button.
    reg [3:0]debouncecounter0 = 4'h0;
	 reg [3:0]debouncecounter1 = 4'h0;
	 reg [3:0]debouncecounter2 = 4'h0;
	 reg [3:0]debouncecounter3 = 4'h0;
	 
	 //keep track of whether or not the buttons are pressed or released.
	 reg buttonstate0 = 1'b0;
	 reg buttonstate1 = 1'b0;
	 reg buttonstate2 = 1'b0;
	 reg buttonstate3 = 1'b0;	

    //1 KHz clock.
    reg ce1k = 1'b0;	 
	 
	 //Clock divider counter.
	 reg [15:0]counter = 16'h0000;
	 
	 always @(posedge clk) begin
		  counter <= counter + 1;
		  ce1k <= 0;
		  if(counter == 16'd50000) begin
		      counter <= 16'b0;  
				ce1k <= 1;
		  end									  
    end
	 
	 always@(posedge ce1k) begin		  
		  
		  /************************Button 0**********************/
		  //Initiate counter.
	     if(buttonstate0 != in_button[0] && !debouncecounter0)
	         debouncecounter0 <= debouncecounter0 + 1;
				
		  //Keep counting.
		  if(debouncecounter0)
		      debouncecounter0 <= debouncecounter0 + 1;
				
		  //Button pressed confirmed.  Change state.
		  if(debouncecounter0 == 4'hf && buttonstate0 != in_button[0]) begin
		      debouncecounter0 <= 0;
				buttonstate0     <= ~buttonstate0;
				out_button[0]    <= ~buttonstate0;
		  end		  
		  
		  /************************Button 1**********************/
		  //Initiate counter.
	     if(buttonstate1 != in_button[1] && !debouncecounter1)
	         debouncecounter1 <= debouncecounter1 + 1;
				
		  //Keep counting.
		  if(debouncecounter1)
		      debouncecounter1 <= debouncecounter1 + 1;
				
		  //Button pressed confirmed.  Change state.
		  if(debouncecounter1 == 4'hf && buttonstate1 != in_button[1]) begin
		      debouncecounter1 <= 0;
				buttonstate1     <= ~buttonstate1;
				out_button[1]    <= ~buttonstate1;
		  end		  
		  
		  /************************Button 2**********************/
		  //Initiate counter.
	     if(buttonstate2 != in_button[2] && !debouncecounter2)
	         debouncecounter2 <= debouncecounter2 + 1;
				
		  //Keep counting.
		  if(debouncecounter2)
		      debouncecounter2 <= debouncecounter2 + 1;
				
		  //Button pressed confirmed.  Change state.
		  if(debouncecounter2 == 4'hf && buttonstate2 != in_button[2]) begin
		      debouncecounter2 <= 0;
				buttonstate2     <= ~buttonstate2;
				out_button[2]    <= ~buttonstate2;
		  end		  
		  
		  /************************Button 3**********************/
		  //Initiate counter.
	     if(buttonstate3 != in_button[3] && !debouncecounter3)
	         debouncecounter3 <= debouncecounter3 + 1;
				
		  //Keep counting.
		  if(debouncecounter3)
		      debouncecounter3 <= debouncecounter3 + 1;
				
		  //Button pressed confirmed.  Change state.
		  if(debouncecounter3 == 4'hf && buttonstate3 != in_button[3]) begin
		      debouncecounter3 <= 0;
				buttonstate3     <= ~buttonstate3;
				out_button[3]    <= ~buttonstate3;
		  end		      
	 
	 end

endmodule
