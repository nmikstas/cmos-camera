`timescale 1ns / 1ps

//Register select defines.
`define REGISTER_SELECT_RCR     2'b00
`define REGISTER_SELECT_BCR     2'b10
`define REGISTER_SELECT_DIDR    2'b01
	 
//Defines for BCR register.
`define OP_MODE_SYNCHRONOUS     1'b0
`define OP_MODE_ASYNCHRONOUS    1'b1

`define INITIAL_ACCESS_VARIABLE 1'b0
`define INITIAL_ACCESS_FIXED    1'b1
	 
`define LATENCY_COUNTER_CODE8   3'b000
`define LATENCY_COUNTER_CODE1   3'b001
`define LATENCY_COUNTER_CODE2   3'b010
`define LATENCY_COUNTER_CODE3   3'b011
`define LATENCY_COUNTER_CODE4   3'b100
`define LATENCY_COUNTER_CODE5   3'b101
`define LATENCY_COUNTER_CODE6   3'b110
`define LATENCY_COUNTER_CODE7   3'b111
	 
`define WAIT_POLARITY_LOW       1'b0
`define WAIT_POLARITY_HIGH      1'b1
	 
`define WAIT_CONFIG_DURING      1'b0
`define WAIT_CONFIG_BEFORE      1'b1
	 
`define DRIVE_STRENGTH_FULL     2'b00
`define DRIVE_STRENGTH_HALF     2'b01
`define DRIVE_STRENGTH_QUARTER  2'b10
	 
`define BURST_WRAP_YES          1'b0
`define BURST_WRAP_NO           1'b1
	 
`define BURST_LENGTH_4          3'b001
`define BURST_LENGTH_8          3'b010
`define BURST_LENGTH_16         3'b011
`define BURST_LENGTH_32         3'b100
`define BURST_LENGTH_CONT       3'b111

module CellRAMBurstController(
    output busy,											//
	 input  clk,											//
	 input  write,											//Control and status interface.
	 input  [15:0]data,									//
	 input  [15:0]id,										//
	 
	 input  [10:0]writeBufAddr,						//
	 input  [7:0]writeBufData,						//Write buffer interface.
	 input  writeBufClk,									//
	 input  writeBufWE,									//
	 
	 input  [9:0]readBufAddr,							//
	 output reg [15:0]readBufData = 16'h0000,		//Read buffer interface.
	 input  readBufClk,									//
	 
	 //Cellular RAM interface.
	 output LB,												//Constantly enable output lower byte.  
	 output UB,  											//Constantly enable output upper byte.
	 output reg OE  = 1'b1,								//Output enable.
	 output reg WE  = 1'b1,								//Write enable.
	 output reg ADV = 1'b1,								//Address enable.
	 output reg CE  = 1'b1,								//Chip enable.
	 output reg CRE = 1'b1,								//Control register enable.
	 output RAM_CLK, 										//Clock.
	 input  O_WAIT,  										//Wait signal. 
    output reg [22:0]A = 23'h000000,				//Address.
	 inout [15:0]DQ										//Data.
	 );

    assign LB = 1'b0;
	 assign UB = 1'b0;

	 //--------------------------------Interface Parameters--------------------------------
	 
	 parameter BURST_WRITE    = 16'h0050;		//Initiate burst write.
	 parameter BURST_READ     = 16'h0051;		//Initiate burst read.
	 parameter WRITE_LENGTH   = 16'h0052;		//Set lower word of write length.
	 parameter READ_LENGTH    = 16'h0053;		//Set lower word of read length.
	 parameter WRITE_ADDR_H   = 16'h0054;		//Set upper 7 bits of cell RAM write address.
	 parameter WRITE_ADDR_L   = 16'h0055;		//Set lower word of cell RAM write address.
	 parameter READ_ADDR_H    = 16'h0056;		//Set upper 7 bits of cell RAM read address.
	 parameter READ_ADDR_L    = 16'h0057;		//Set lower word of cell RAM read address.
	 parameter SET_WB_ADDR    = 16'h0058;		//Set address of write buffer (cell RAM interface).
	 parameter SET_RB_ADDR    = 16'h0059;		//Set address of read buffer (cell RAM interface).
	 
	 //-----------------------------Main Control Registers---------------------------------
	 
	 reg  sinkWE               = 1'b0;			//Write enable from memory controller to read buffer.
	 reg  [9:0]sinkAddr        = 10'h000; 		//Address from memory controller to read buffer.
	 
	 wire [15:0]sourceData;							//Data from write buffer to memory controller.
	 reg  [9:0]sourceAddr      = 10'h000; 		//Address from write buffer to memory controller.
	 
	 reg  [22:0]burstWriteAddr = 23'h000000;	//Starting address of burst write.
	 reg  [10:0]bytesToWrite   = 11'h000;		//Number of bytes to write.
	 
	 reg  [22:0]thisWriteAddr  = 23'h000000;
	 reg  [10:0]writeCounter   = 11'h000;
	 
	 reg  [22:0]burstReadAddr  = 23'h000000;	//Starting address of burst read.
	 reg  [10:0]bytesToRead    = 11'h000;		//Number of bytes to read.
	 
	 reg  [22:0]thisReadAddr	= 23'h000000;
	 reg  [10:0]readCounter    = 11'h000;
	 
	 //-----------------------------------Block RAMs---------------------------------------
	 
	 parameter RAM_WIDTH     = 16;
    parameter RAM_ADDR_BITS = 10;

    /*read buffer*/
    reg [RAM_WIDTH-1:0] readBuffer [(2**RAM_ADDR_BITS)-1:0];

    always @(posedge clk)
        if (sinkWE)
            readBuffer[sinkAddr] <= DQ;
      
    always @(posedge readBufClk)
        readBufData <= readBuffer[readBufAddr];

    /*write buffer*/
    RAMBuffer writeBuffer (
        .clka(writeBufClk), 	// input clka
        .wea(writeBufWE),		// input [0 : 0] wea
        .addra(writeBufAddr), // input [10 : 0] addra
        .dina(writeBufData), 	// input [7 : 0] dina
		  
        .clkb(clk),				// input clkb
        .addrb(sourceAddr), 	// input [9 : 0] addrb
        .doutb(sourceData) 	// output [15 : 0] doutb
    );

	 //--------------------------Cellular RAM State Machine--------------------------------
	 
	 localparam IDLE					= 5'h00;
	 
	 localparam CONFIG0    			= 5'h01;	 
	 localparam CONFIG1		 		= 5'h02;
	 localparam CONFIG2		 		= 5'h03;
	 localparam CONFIG3		 		= 5'h04;
	 localparam CONFIG4		 		= 5'h05;
	 localparam CONFIG5		 		= 5'h06;
	 localparam CONFIG6		 		= 5'h07;
	 localparam CONFIG7		 		= 5'h08;
	 localparam CONFIG8		 		= 5'h09;
	 localparam CONFIG9		 		= 5'h0A;
	 localparam CONFIG10		 		= 5'h0B;
	 localparam CONFIG11		 		= 5'h0C;	 
	 
	 localparam WRITE_BYTE0			= 5'h0D;
	 localparam WRITE_BYTE1			= 5'h0E;
	 localparam WRITE_BYTE2			= 5'h0F;	 
	 localparam WRITE_BYTE3			= 5'h10;
	 localparam WRITE_BYTE4			= 5'h11;
	 
	 localparam WRITE_RBC0			= 5'h12;
	 localparam WRITE_RBC1			= 5'h13; 
	 
	 localparam READ_BYTE0			= 5'h14;
	 localparam READ_BYTE1			= 5'h15;
	 localparam READ_BYTE2			= 5'h16;
	 localparam READ_BYTE3			= 5'h17;
	 localparam READ_BYTE4			= 5'h18;	 
	 
	 localparam READ_RBC0			= 5'h19;
	 localparam READ_RBC1			= 5'h1A;
	 
	 reg [4:0]state      			= CONFIG0;
	 reg [4:0]next_state 			= CONFIG0;
	 reg [7:0]state_cntr				= 8'h00;
	 reg clk_enable       			= 1'b0;
	 
	 //Indicate if the controller is currently busy.
	 assign busy = (state == IDLE) ? 1'b0 : 1'b1;
	 
	 /* Bi-directional port control */
	 reg [15:0]data_out_enable = 16'h0000;
    
	 /* Enable/disable data output */
    assign DQ[0]  = data_out_enable[0]  ? sourceData[0]  : 1'bz;   
	 assign DQ[1]  = data_out_enable[1]  ? sourceData[1]  : 1'bz;
	 assign DQ[2]  = data_out_enable[2]  ? sourceData[2]  : 1'bz;
	 assign DQ[3]  = data_out_enable[3]  ? sourceData[3]  : 1'bz;
	 assign DQ[4]  = data_out_enable[4]  ? sourceData[4]  : 1'bz;
	 assign DQ[5]  = data_out_enable[5]  ? sourceData[5]  : 1'bz;
	 assign DQ[6]  = data_out_enable[6]  ? sourceData[6]  : 1'bz;
	 assign DQ[7]  = data_out_enable[7]  ? sourceData[7]  : 1'bz;
	 assign DQ[8]  = data_out_enable[8]  ? sourceData[8]  : 1'bz;
	 assign DQ[9]  = data_out_enable[9]  ? sourceData[9]  : 1'bz;
	 assign DQ[10] = data_out_enable[10] ? sourceData[10] : 1'bz;
	 assign DQ[11] = data_out_enable[11] ? sourceData[11] : 1'bz;
	 assign DQ[12] = data_out_enable[12] ? sourceData[12] : 1'bz;
	 assign DQ[13] = data_out_enable[13] ? sourceData[13] : 1'bz;
	 assign DQ[14] = data_out_enable[14] ? sourceData[14] : 1'bz;
	 assign DQ[15] = data_out_enable[15] ? sourceData[15] : 1'bz;
	 
	 //Enable RAM clock only if clock enable is active (not active during config).
	 assign RAM_CLK = clk_enable ? clk : 0;
	 
	 always @(negedge clk) begin
	     state <= next_state;
		  
		  /*********************************Interface Control********************************/
		  if(id == BURST_READ && write && !busy && bytesToRead) begin
		      state <= READ_BYTE0;
		  end
		  
		  if(id == BURST_WRITE && write && !busy && bytesToWrite) begin
		      state <= WRITE_BYTE0;
		  end
		 
		  if(id == WRITE_LENGTH && write && !busy) begin
		      bytesToWrite <= data[10:0];
		  end
		  
		  if(id == READ_LENGTH && write && !busy) begin
		      bytesToRead <= data[10:0];
		  end
		  
		  if(id == WRITE_ADDR_H  && write && !busy) begin
		      burstWriteAddr[22:16] <= data[6:0];
		  end
		  
		  if(id == WRITE_ADDR_L && write && !busy) begin
		      burstWriteAddr[15:0] <= data;
		  end
		  
		  if(id == READ_ADDR_H && write && !busy) begin
		      burstReadAddr[22:16] <= data[6:0];
		  end
		  
		  if(id == READ_ADDR_L && write && !busy) begin
		      burstReadAddr[15:0] <= data;
		  end
		  
		  if(id == SET_WB_ADDR && write && !busy) begin
		      sourceAddr <= data[9:0];
		  end
		  
		  if(id == SET_RB_ADDR && write && !busy) begin
		      sinkAddr <= data[9:0];
		  end
				
		  /*********************Cellular RAM Configuration State Machine*********************/				
		  if(state == CONFIG0) begin
		      clk_enable <= 0;
				CRE        <= 0;
				ADV        <= 1;
		      CE         <= 1;
				OE         <= 1;
				WE         <= 1;				
		  end
		  
		  //Load BCR register.
		  if(state == CONFIG1) begin
		      A   <= {3'h0, `REGISTER_SELECT_BCR, 2'h0, `OP_MODE_SYNCHRONOUS,
                    `INITIAL_ACCESS_VARIABLE, `LATENCY_COUNTER_CODE3, `WAIT_POLARITY_HIGH,
						  1'h0, `WAIT_CONFIG_BEFORE, 2'h0, `DRIVE_STRENGTH_FULL, 
						  `BURST_WRAP_NO, `BURST_LENGTH_CONT};
				state_cntr <= 2;
				CRE        <= 1;				
		  end
		  
		  if(state == CONFIG2) begin
            state_cntr <= state_cntr - 1;		  
				ADV <= 0;
				CE  <= 0;
				WE  <= 0;
		  end
		  
		  if(state == CONFIG3) begin
		     state_cntr <= 5;
           ADV        <= 1;
		  end
		  
		  if(state == CONFIG4) begin
            state_cntr <= state_cntr - 1;		  
		  end
		  
		  if(state == CONFIG5) begin
				CE  <= 1;				
		  end
		  
		  if(state == CONFIG6) begin
		      A   <= 23'h000000;
            WE  <= 1;				
		  end
		  
		  //Config write complete.  Perform read as per TRM.
		  if(state == CONFIG7) begin
            state_cntr <= 1;		  
				CRE        <= 0;
				ADV        <= 0;
				CE         <= 0;
				OE         <= 0;
		  end
		  
		  if(state == CONFIG8) begin
            state_cntr <= state_cntr - 1;			  
		  end
		  
		  if(state == CONFIG9) begin
            state_cntr <= 5;		  
	         ADV        <= 1;
		  end
		  
		  if(state == CONFIG10) begin
            state_cntr <= state_cntr - 1;		  
		  end
		  
		  if(state == CONFIG11) begin	
           CE  <= 1;
			  OE  <= 1;		  
		  end 	  
		 
		  /*************************Cellular RAM Write State Machine*************************/			  
		  if(state == WRITE_BYTE0) begin						//Initialize write.
		      thisWriteAddr   <= burstWriteAddr;			//
		      writeCounter    <= bytesToWrite;				//Make copies of user provided values.
		      data_out_enable <= 16'hFFFF;
		      clk_enable      <= 1'b1;
		      A               <= burstWriteAddr;
				ADV             <= 0;
				CE              <= 0;
				WE              <= 0;
		  end
		  
		  if(state == WRITE_BYTE1) begin						//Indicate address is valid.
		      ADV <= 1;				
		  end
		  
		  if(state == WRITE_BYTE2) begin  					//Wait for O_WAIT to go low.
		      if(!O_WAIT) begin						    
					 writeCounter <= writeCounter - 1;
					 sourceAddr   <= sourceAddr   + 1;
				end
		  end
		  
		  if(state == WRITE_BYTE3) begin						//Write bytes.
		      if(!O_WAIT) begin									//Check for RBC.
		          writeCounter <= writeCounter - 1;			
				    sourceAddr   <= sourceAddr   + 1;
				end
		      if(writeCounter <= 1) begin					//This state is skipped if only 1 byte to write.
				    WE <= 1; 
				end			
		  end

		  if(state == WRITE_BYTE4) begin					   //Finalize write.
		      if(!O_WAIT) begin								   //If O_WAIT active, RBC entered with 1 byte left to write.
				    data_out_enable <= 16'h0000;
					 clk_enable      <= 0;
                CE              <= 1;
				    WE              <= 1;
				end
		  end
		  
		  if(state == WRITE_RBC0) begin						//Cross row boundary.
		      thisWriteAddr <= burstWriteAddr + (bytesToWrite - writeCounter - 1);
		      writeCounter  <= writeCounter   + 1;		//Wait is delayed so counters need to be undone up by 1.		
				sourceAddr    <= sourceAddr     - 1;		//
		      CE            <= 1;
		  end
		  
		  if(state == WRITE_RBC1) begin
		      A   <= thisWriteAddr;
		      CE  <= 0;
				WE  <= 0;
				ADV <= 0;
		  end	
		  
		  /*************************Cellular RAM Read State Machine**************************/		  
		  if(state == READ_BYTE0) begin						//Initialize read.
		      thisReadAddr   <= burstReadAddr;				//
		      readCounter    <= bytesToRead;				//Make copies of user provided values.
				clk_enable     <= 1'b1;				
            A              <= burstReadAddr;
				ADV            <= 0;
				CE             <= 0;
				WE             <= 1;		
				OE             <= 0;
		  end
		  
		  if(state == READ_BYTE1) begin						//Indicate address is valid.
		      readCounter <= readCounter - 1;
				sinkWE      <= 0;
            ADV         <= 1;  
		  end
		  		 
        if(state == READ_BYTE2) begin						//Wait for O_WAIT to go low.
            if(!O_WAIT)
				    sinkWE <= 1;
            if(!readCounter && !O_WAIT) begin			//Only one byte to read.
                CE <= 1;
				    OE <= 1;
            end				
		  end

        if(state == READ_BYTE3) begin						//Write bytes.
		      if(!O_WAIT) begin									//Check for RBC.
                readCounter <= readCounter - 1;
				    sinkAddr    <= sinkAddr + 1;
				    sinkWE      <= 1;
				end
				if(readCounter <= 1) begin						//This state is skipped if only 1 byte to read.
                CE <= 1;
            end					 
		  end
		  
		  if(state == READ_BYTE4) begin						//Finalize read.
		      clk_enable <= 0;
				sinkWE     <= 0;
		      CE         <= 1;
				OE         <= 1;
				sinkAddr   <= sinkAddr + 1;
		  end
		  
		  if(state == READ_RBC0) begin						//Cross row boundary.
		      thisReadAddr <= burstReadAddr + (bytesToRead - readCounter);
				sinkAddr     <= sinkAddr + 1;
				CE           <= 1;
		  end
		  
		  if(state == READ_RBC1) begin
		      A   <= thisReadAddr;
		      CE  <= 0;
				ADV <= 0;
		  end
    end
	 
	 always @(*) begin
	     case(state)
				/****************************Config****************************/
				CONFIG0    :	next_state = CONFIG1;
				CONFIG1    :	next_state = CONFIG2;
				CONFIG2    :	next_state = !state_cntr ? CONFIG3  : CONFIG2;
		      CONFIG3    :	next_state = CONFIG4;
				CONFIG4    :	next_state = !state_cntr ? CONFIG5  : CONFIG4;
				CONFIG5    :	next_state = CONFIG6;
				CONFIG6    :	next_state = CONFIG7;
				CONFIG7    :	next_state = CONFIG8;
				CONFIG8    :	next_state = !state_cntr ? CONFIG9  : CONFIG8;
				CONFIG9    :	next_state = CONFIG10;
				CONFIG10   :	next_state = !state_cntr ? CONFIG11 : CONFIG10;
				CONFIG11   :	next_state = IDLE;
				
				WRITE_BYTE0:	next_state =  WRITE_BYTE1;
				WRITE_BYTE1:	next_state =  WRITE_BYTE2;				
				WRITE_BYTE2:   next_state = (!O_WAIT && writeCounter == 1) ? WRITE_BYTE4 :    //Special case when only 1 byte to write.
				                             !O_WAIT                       ? WRITE_BYTE3 :
													  WRITE_BYTE2;													  
            WRITE_BYTE3:   next_state =  O_WAIT                        ? WRITE_RBC0  :
				                            (writeCounter <= 1)            ? WRITE_BYTE4 :
													  WRITE_BYTE3;
				WRITE_BYTE4:   next_state =  O_WAIT                        ? WRITE_RBC0  :
				                             IDLE;
				
				WRITE_RBC0 :	next_state =  WRITE_RBC1;
				WRITE_RBC1 :	next_state =  WRITE_BYTE1;
				
				/*****************************Read*****************************/				
				READ_BYTE0 :   next_state =  READ_BYTE1;
				READ_BYTE1 :   next_state =  READ_BYTE2;				
				READ_BYTE2 :   next_state = (!O_WAIT && !readCounter) 	  ? READ_BYTE4  :    //Special case when only 1 byte to read.
				                             !O_WAIT                       ? READ_BYTE3  :
													  READ_BYTE2;
				READ_BYTE3 :   next_state =  O_WAIT                        ? READ_RBC0   :
				                            (readCounter <= 1)             ? READ_BYTE4  :
				                             READ_BYTE3;
				READ_BYTE4 :	next_state =  IDLE;
				
				READ_RBC0  :	next_state =  READ_RBC1;
				READ_RBC1  :	next_state =  READ_BYTE1;
				
				/**************************************************************/
		      default    :	next_state = IDLE;
		  endcase
	 end  
endmodule
