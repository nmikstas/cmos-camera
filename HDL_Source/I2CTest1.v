`timescale 1ns / 1ps

`define MASTER_TX_SP    (clock_rate_counter <= (clock_rate_set / 2))
`define MASTER_TX_NEXT  ((clock_rate_counter == (clock_rate_set / 2)) && !scl_in)
`define MASTER_TX_HIGH  ((clock_rate_counter == (clock_rate_set / 2)) && scl_in)
`define NEXT_BYTE_VALID enable_master_fsm && tx_valid_buffer
`define THIS_BYTE_VALID enable_master_fsm && tx_valid_work_reg
`define POSEDGE_DETECT  !last_scl && scl_in
`define NEGEDGE_DETECT  last_scl && !scl_in

module I2CTest1(
    inout  SCL,
	 inout  SDA,
	 input  reset,
	 input  write,
    input  clk,
	 input  [15:0]id,
	 input  [15:0]din,
	 output reg [7:0]i2cdata = 8'h00,
	 output reg [15:0]i2cstatus = 16'h0003 //master inactive, tx valid.
    );
	 
/******************************* Parameters ******************************/

    parameter LOAD_CLOCK_RATE     = 16'h8000;
	 parameter LOAD_MASTER_TX_DATA = 16'h8001;
	 parameter LOAD_MASTER_TYPE    = 16'h8002;
	 parameter MASTER_ENABLED      = 16'h8003;
	 parameter TX_BYTE_VALID		 = 16'h8004;
	 parameter RX_VALID            = 16'h8005;
	
	 
	 //High Impedance. Bus is driven by pull-up resistor.
	 localparam BUS_HIGH           = 1'bz; 
	 localparam BUS_LOW            = 1'b0;
	 localparam DISABLED           = 1'b0;
	 localparam ENABLED            = 1'b1;
	 
	 //SCL states.
	 localparam CLOCK_INACTIVE    = 2'b00;
	 localparam CLOCK_CHECK_HIGH  = 2'b01; //Used to synchronize.
	 localparam CLOCK_HIGH        = 2'b10;
	 localparam CLOCK_LOW         = 2'b11;
	 
	 //Master TX states.
	 localparam MASTER_INACTIVE   = 5'h00;
	 localparam MASTER_TX_READY   = 5'h01;
	 localparam MASTER_TX_START   = 5'h02;
	 localparam MASTER_TX_BIT7    = 5'h03;
	 localparam MASTER_TX_BIT6    = 5'h04;
	 localparam MASTER_TX_BIT5    = 5'h05;
	 localparam MASTER_TX_BIT4    = 5'h06;
	 localparam MASTER_TX_BIT3    = 5'h07;
	 localparam MASTER_TX_BIT2    = 5'h08;
	 localparam MASTER_TX_BIT1    = 5'h09;
	 localparam MASTER_TX_BIT0    = 5'h0A;
	 localparam MASTER_TX_ACK     = 5'h0B;
	 localparam MASTER_TX_PREP    = 5'h0C;
	 localparam MASTER_TX_STOP    = 5'h0D;
	 localparam MASTER_RX_BIT7		= 5'h10;
	 localparam MASTER_RX_BIT6		= 5'h11;
	 localparam MASTER_RX_BIT5		= 5'h12;
	 localparam MASTER_RX_BIT4		= 5'h13;
	 localparam MASTER_RX_BIT3		= 5'h14;
	 localparam MASTER_RX_BIT2		= 5'h15;
	 localparam MASTER_RX_BIT1		= 5'h16;
	 localparam MASTER_RX_BIT0		= 5'h17;
	 localparam MASTER_RX_ACK     = 5'h18;
	 
	 //Start, stop or continue at end of transmission.
	 localparam MASTER_P          = 2'b00; //Stop.
	 localparam MASTER_S          = 2'b01; //Start.
	 localparam MASTER_TX_C       = 2'b10; //Tx continue.
	 localparam MASTER_RX_C       = 2'b11; //Rx continue.
	 
/******************************* IO Control ******************************/	 

    //SDA and SCL output enable registers.
	 reg scl_enable = DISABLED;
	 reg sda_enable = DISABLED;
	 
	 wire scl_in, sda_in;
	 assign scl_in = SCL;
	 assign sda_in = SDA;
	 
	 //Pull-up resistors drive output high.
	 //Device can only drive output low.
    assign SCL = scl_enable ? BUS_LOW : BUS_HIGH;
	 assign SDA = sda_enable ? BUS_LOW : BUS_HIGH;
	 
	 //For simulation only!
	 //assign SCL = scl_enable ? 1'b0 : 1'b1;
	 //assign SDA = sda_enable ? 1'b0 : 1'b1;
	 
/**************************** Misc. Registers ****************************/
	 
	 //Calculation for SCL is: System_Clock / Desired_SCL / 2. 
		 
	 //Reference register used to set the counter register.
	 reg [15:0]clock_rate_set     = 250; // 100KHz default at 50MHz system clock.
	 //Down counter that generates the SCL frequency.
    reg [15:0]clock_rate_counter = 250;
	 
	 //Wait register used for minimum time between stop bit and next start bit.
	 reg [15:0]master_tx_wait;
	 
	 //Wait a certain amount of time before sampling input.
	 reg [15:0]master_rx_wait;
	 
	 //Enable regs for low level finite state machines.
	 reg enable_clock_fsm  = DISABLED;
	 reg enable_master_fsm = DISABLED;

    //Registers used to detect start and stop conditions and clock edges.
    reg last_scl = 1'b1;	 
	 //reg last_sda;

    //flip-flops used to detect start and stop conditions.
    //reg start_detected;
	 //reg stop_detected;
	 
	 //Registers used for storing tx data and start/stop data.
	 reg [7:0]data_tx_buffer       = 8'h00;
	 reg [7:0]master_tx_work_reg   = 8'h00;	 
	 reg [1:0]type_buffer          = 2'b00;
	 reg [1:0]master_type_work_reg = 2'b00;
	 reg tx_valid_buffer           = 1'b0;
	 reg tx_valid_work_reg         = 1'b0;
	 reg rx_valid                  = 1'b0;
	 
/**************************** State Registers ****************************/

	 reg [1:0]clock_state          = 2'h0;
	 reg [1:0]clock_next_state     = 2'h0;
	 
	 reg [4:0]master_state         = 5'h00;
	 reg [4:0]master_next_state    = 5'h00;

/***************************** Reset control *****************************/

    always @(posedge clk) begin
	     if(reset) begin
		      clock_state       <= CLOCK_INACTIVE;
				master_state      <= MASTER_INACTIVE;
				enable_clock_fsm  <= DISABLED;
				enable_master_fsm <= DISABLED;
				scl_enable        <= DISABLED;
		  end

/********************* State And Next State Control **********************/
	 
	     else begin
		      clock_state  <= clock_next_state;
				master_state <= master_next_state;
				last_scl     <= scl_in;
				
/***************************** Status bits *******************************/				
				
				if(tx_valid_buffer) //1 if next byte to tx is valid, 0 if not.
				    i2cstatus[0] = 1'b0;
				else
				    i2cstatus[0] = 1'b1;
					 
				if(master_state == MASTER_INACTIVE) //1 if inactive, 0 if not.
				    i2cstatus[1] = 1'b1;
				else
				    i2cstatus[1] = 1'b0;
					 
				if(rx_valid)
				    i2cstatus[2] = 1'b1;
				else
				    i2cstatus[2] = 1'b0;
				
/************************* Clock State Control ***************************/
				
				if(clock_state == CLOCK_INACTIVE) begin
				    scl_enable         <= DISABLED;
					 clock_rate_counter <= clock_rate_set;
				end
				
				if(clock_state == CLOCK_CHECK_HIGH) begin
				    clock_rate_counter <= clock_rate_set;
				    scl_enable         <= DISABLED;
				end
				
				if(clock_state == CLOCK_CHECK_HIGH && clock_next_state == CLOCK_HIGH) begin
				    clock_rate_counter <= clock_rate_set - 2'b10; //Tweek this for accurate clock.
					 scl_enable         <= DISABLED;
				end
				
				if(clock_state == CLOCK_HIGH && clock_next_state == CLOCK_HIGH) begin
				    clock_rate_counter <= clock_rate_counter - 1'b1;
					 scl_enable         <= DISABLED;
				end
				
				if(clock_state == CLOCK_HIGH && clock_next_state == CLOCK_LOW) begin
				    clock_rate_counter <= clock_rate_set - 2'b01; //Tweek this for accurate clock.
					 scl_enable         <= ENABLED;
				end
				
				if(clock_state == CLOCK_LOW && clock_next_state == CLOCK_LOW) begin
				    clock_rate_counter <= clock_rate_counter - 1'b1;
					 scl_enable         <= ENABLED;
				end
				
				if(clock_state == CLOCK_LOW && clock_next_state == CLOCK_CHECK_HIGH) begin
					 scl_enable         <= DISABLED;
				end
				
/*********************** Master TX State Control *************************/

            if(master_state == MASTER_INACTIVE) begin
				    sda_enable       <= DISABLED;
					 enable_clock_fsm <= DISABLED;
				end

            if((master_state == MASTER_INACTIVE) && master_next_state == MASTER_TX_READY) begin
				    enable_clock_fsm      <= ENABLED;
					 sda_enable            <= DISABLED;
					 master_type_work_reg  <= type_buffer;    //Load start/stop bit.
					 type_buffer           <= 2'b00;          //Clear type buffer.
                master_tx_work_reg    <= data_tx_buffer; //Load data to transmit.
                data_tx_buffer        <= 8'h00;          //Clear data buffer.
	             tx_valid_work_reg     <= tx_valid_buffer;//Load tx valid bit.
					 tx_valid_buffer       <= 1'b0;           //Clear tx valid buffer.
				end
				
				if(master_state == MASTER_TX_READY && master_next_state == MASTER_TX_START) begin				
				    sda_enable <= ENABLED;
				end
				
				if(master_state == MASTER_TX_START && master_next_state == MASTER_TX_BIT7) begin
				    sda_enable <= ~master_tx_work_reg[7];
				end
				
				if(master_state == MASTER_TX_BIT7 && master_next_state == MASTER_TX_BIT6) begin
				    sda_enable <= ~master_tx_work_reg[6];
				end
				
				if(master_state == MASTER_TX_BIT6 && master_next_state == MASTER_TX_BIT5) begin
				    sda_enable <= ~master_tx_work_reg[5];
				end
				
				if(master_state == MASTER_TX_BIT5 && master_next_state == MASTER_TX_BIT4) begin
				    sda_enable <= ~master_tx_work_reg[4];
				end
				
				if(master_state == MASTER_TX_BIT4 && master_next_state == MASTER_TX_BIT3) begin
				    sda_enable <= ~master_tx_work_reg[3];
				end
				
				if(master_state == MASTER_TX_BIT3 && master_next_state == MASTER_TX_BIT2) begin
				    sda_enable <= ~master_tx_work_reg[2];
				end
				
				if(master_state == MASTER_TX_BIT2 && master_next_state == MASTER_TX_BIT1) begin
				    sda_enable <= ~master_tx_work_reg[1];
				end
				
				if(master_state == MASTER_TX_BIT1 && master_next_state == MASTER_TX_BIT0) begin
				    sda_enable <= ~master_tx_work_reg[0];
				end
				
				if(master_state == MASTER_TX_BIT0 && master_next_state == MASTER_TX_ACK) begin
				    sda_enable <= DISABLED;
				end
				
				if(master_state == MASTER_TX_ACK && master_next_state == MASTER_TX_PREP) begin				
				    if(master_type_work_reg == MASTER_S) begin
					     sda_enable <= DISABLED;
					 end
					 
					 else if(master_type_work_reg == MASTER_TX_C) begin
					     master_tx_work_reg <= data_tx_buffer;
						  sda_enable <= ~data_tx_buffer[7];						  
					 end
					 
					 else if(master_type_work_reg == MASTER_RX_C) begin
					     sda_enable <= DISABLED;
					 end
					 
					 else begin
					     sda_enable <= ENABLED;
					 end
				end
				
				if(master_state == MASTER_TX_PREP && master_next_state == MASTER_TX_STOP) begin
				    sda_enable  <= DISABLED;
					 master_tx_wait   <= clock_rate_set / 2 - 2'b11; //Tweek this for wait after stop.
				end
				
				if(master_state == MASTER_TX_PREP && master_next_state == MASTER_TX_START) begin
				    master_type_work_reg  <= type_buffer;    //Load start/stop bit.
					 type_buffer           <= 2'b00;          //Clear type buffer.
                master_tx_work_reg    <= data_tx_buffer; //Load data to transmit.
                data_tx_buffer        <= 8'h00;          //Clear data buffer.
					 tx_valid_work_reg     <= tx_valid_buffer;//Load tx valid bit.
					 tx_valid_buffer       <= 1'b0;           //Clear tx valid buffer.
				    sda_enable <= ENABLED;
				end
				
				if(master_state == MASTER_TX_PREP && master_next_state == MASTER_TX_BIT7) begin
				    master_type_work_reg  <= type_buffer;    //Load start/stop bit.
					 type_buffer           <= 2'b00;          //Clear type buffer.
                master_tx_work_reg    <= data_tx_buffer; //Load data to transmit.
                data_tx_buffer        <= 8'h00;          //Clear data buffer.
					 tx_valid_work_reg     <= tx_valid_buffer;//Load tx valid bit.
					 tx_valid_buffer       <= 1'b0;           //Clear tx valid buffer.
				end
				
				if(master_state == MASTER_TX_STOP) begin
				    enable_clock_fsm <= DISABLED;
					 sda_enable       <= DISABLED;					 
					 master_tx_wait   <= master_tx_wait - 1'b1;
				end
				
				if(master_state == MASTER_TX_STOP && master_next_state == MASTER_INACTIVE) begin
				    enable_master_fsm <= DISABLED; //Stop at end of transmission.
				end
				
/*********************** Master RX State Control *************************/

            if(master_state == MASTER_TX_PREP && master_next_state == MASTER_RX_BIT7) begin
				    rx_valid             <= 1'b0;
					 master_type_work_reg <= type_buffer;    //Load start/stop bit.
					 type_buffer          <= 2'b00;          //Clear type buffer.					 
					 tx_valid_work_reg    <= tx_valid_buffer;//Load tx valid bit.
					 tx_valid_buffer      <= 1'b0;           //Clear tx valid buffer.
					 sda_enable           <= DISABLED;
					 i2cdata[7]           <= sda_in;
					 //master_rx_wait       <= clock_rate_set / 2;
				end
				
				/*if(master_state == MASTER_RX_BIT7) begin
				    master_rx_wait <= master_rx_wait - 1'b1;
					 if(!master_rx_wait)
				        i2cdata[7]       <= sda_in;
				end*/

            if(master_state == MASTER_RX_BIT7 && master_next_state == MASTER_RX_BIT6) begin
				    i2cdata[6] <= sda_in;
					 //master_rx_wait       <= clock_rate_set / 2;
				end
				
				/*if(master_state == MASTER_RX_BIT6) begin
				    master_rx_wait <= master_rx_wait - 1'b1;
					 if(!master_rx_wait)
				        i2cdata[6]       <= sda_in;
				end*/
				
				if(master_state == MASTER_RX_BIT6 && master_next_state == MASTER_RX_BIT5) begin
				    i2cdata[5] <= sda_in;
					 //master_rx_wait       <= clock_rate_set / 2;
				end
				
				/*if(master_state == MASTER_RX_BIT5) begin
				    master_rx_wait <= master_rx_wait - 1'b1;
					 if(!master_rx_wait)
				        i2cdata[5]       <= sda_in;
				end*/
				
				if(master_state == MASTER_RX_BIT5 && master_next_state == MASTER_RX_BIT4) begin
				    i2cdata[4] <= sda_in;
					 //master_rx_wait       <= clock_rate_set / 2;
				end
				
				/*if(master_state == MASTER_RX_BIT4) begin
				    master_rx_wait <= master_rx_wait - 1'b1;
					 if(!master_rx_wait)
				        i2cdata[4]       <= sda_in;
				end*/
				
				if(master_state == MASTER_RX_BIT4 && master_next_state == MASTER_RX_BIT3) begin
				    i2cdata[3] <= sda_in;
					 //master_rx_wait       <= clock_rate_set / 2;
				end
				
				/*if(master_state == MASTER_RX_BIT3) begin
				    master_rx_wait <= master_rx_wait - 1'b1;
					 if(!master_rx_wait)
				        i2cdata[3]       <= sda_in;
				end*/

            if(master_state == MASTER_RX_BIT3 && master_next_state == MASTER_RX_BIT2) begin
				    i2cdata[2] <= sda_in;
					 //master_rx_wait       <= clock_rate_set / 2;
				end
				
				/*if(master_state == MASTER_RX_BIT2) begin
				    master_rx_wait <= master_rx_wait - 1'b1;
					 if(!master_rx_wait)
				        i2cdata[2]       <= sda_in;
				end*/
				
				if(master_state == MASTER_RX_BIT2 && master_next_state == MASTER_RX_BIT1) begin
				    i2cdata[1] <= sda_in;
					 //master_rx_wait       <= clock_rate_set / 2;
				end
				
				/*if(master_state == MASTER_RX_BIT1) begin
				    master_rx_wait <= master_rx_wait - 1'b1;
					 if(!master_rx_wait)
				        i2cdata[1]       <= sda_in;
				end*/
				
				if(master_state == MASTER_RX_BIT1 && master_next_state == MASTER_RX_BIT0) begin
				    rx_valid <= 1'b1;					 
				    i2cdata[0] <= sda_in;
					 //master_rx_wait       <= clock_rate_set / 2;
				end
				
				/*if(master_state == MASTER_RX_BIT0) begin
				    master_rx_wait <= master_rx_wait - 1'b1;
					 if(!master_rx_wait)
				        i2cdata[0]       <= sda_in;
				end*/
				
				if(master_state == MASTER_RX_BIT0 && master_next_state == MASTER_RX_ACK) begin
				    if(master_type_work_reg == MASTER_P || master_type_work_reg == MASTER_S)
					     sda_enable <= DISABLED; //NAK
					 else
					     sda_enable <= ENABLED;  //ACK
				end
				
				if(master_state == MASTER_RX_ACK && master_next_state == MASTER_TX_PREP) begin
				    if(master_type_work_reg == MASTER_P)
					     sda_enable <= ENABLED;
					 else
				        sda_enable <= DISABLED;
				end
					  
/****************** Processor Interface -To Be Removed- ******************/	 
	 
	         if(id == LOAD_CLOCK_RATE && write) //Set clock frequency.
		          clock_rate_set <= din;
		     
	         if(id == MASTER_ENABLED && write) //Begin master tx state machine.
		          enable_master_fsm <= din[0];
					 
				//Load end type for transmitted byte (restart, stop or continue).
				if(id == LOAD_MASTER_TYPE && write) 
				    type_buffer <= din[1:0];
					 
				//Load data to be transmitted.
				if(id == LOAD_MASTER_TX_DATA && write)
				    data_tx_buffer <= din[7:0];
					 
			   //Load bit to tell FSM next byte to tx is valid.
				if(id == TX_BYTE_VALID && write)
				    tx_valid_buffer <= din[0];
				
            //Clear rx valid bit after read.				
				if(id == RX_VALID && write)
				    rx_valid <= din[0];
	     end
	 end


/******************************************************************************************************************************************************
 *                                                                  State Machines                                                                    *
 ******************************************************************************************************************************************************/
 
 
 
/***************************************************************** SCL State Machine ******************************************************************/ 

    always @(*) begin
	     case(clock_state)
		      CLOCK_INACTIVE   : clock_next_state = (enable_clock_fsm)                                 ? CLOCK_CHECK_HIGH : 
				                                                                                           CLOCK_INACTIVE;
				CLOCK_CHECK_HIGH : clock_next_state = (enable_clock_fsm &&  scl_in)                      ? CLOCK_HIGH       :
				                                      (enable_clock_fsm && !scl_in)                      ? CLOCK_CHECK_HIGH :
																                                                       CLOCK_INACTIVE;
				CLOCK_HIGH       : clock_next_state = (enable_clock_fsm && scl_in && clock_rate_counter) ? CLOCK_HIGH       :
				                                      (enable_clock_fsm && !scl_in)                      ? CLOCK_LOW        :
				                                      (enable_clock_fsm && !clock_rate_counter)          ? CLOCK_LOW        :
																                                                       CLOCK_INACTIVE;
				CLOCK_LOW        : clock_next_state = (enable_clock_fsm && clock_rate_counter)           ? CLOCK_LOW        :
				                                      (enable_clock_fsm && !clock_rate_counter)          ? CLOCK_CHECK_HIGH :
																                                                       CLOCK_INACTIVE;
		      default          : clock_next_state = CLOCK_INACTIVE;
		  endcase
	 end  

/**************************************************************** Master State Machine ****************************************************************/	 

    always @(*) begin
	     case(master_state)
		      MASTER_INACTIVE : master_next_state = (enable_master_fsm && tx_valid_buffer)                                       ? MASTER_TX_READY :
				                                                                                                                     MASTER_INACTIVE;
				MASTER_TX_READY :	 master_next_state =(enable_master_fsm &&	`MASTER_TX_SP)                                         ? MASTER_TX_START :
				                                      (enable_master_fsm)                                                          ? MASTER_TX_READY :
				                                                                                                                     MASTER_INACTIVE;
	         MASTER_TX_START : master_next_state = (enable_master_fsm && `MASTER_TX_NEXT)                                       ? MASTER_TX_BIT7  :
				                                      (enable_master_fsm)                                                          ? MASTER_TX_START :
												   					                                                                           MASTER_INACTIVE;
	         MASTER_TX_BIT7  : master_next_state = (enable_master_fsm && `MASTER_TX_NEXT)                                       ? MASTER_TX_BIT6  :
				                                      (enable_master_fsm)                                                          ? MASTER_TX_BIT7  :
																		                                                                           MASTER_INACTIVE;
	         MASTER_TX_BIT6  : master_next_state = (enable_master_fsm && `MASTER_TX_NEXT)                                       ? MASTER_TX_BIT5  :
				                                      (enable_master_fsm)                                                          ? MASTER_TX_BIT6  :
																		                                                                           MASTER_INACTIVE;
	         MASTER_TX_BIT5  : master_next_state = (enable_master_fsm && `MASTER_TX_NEXT)                                       ? MASTER_TX_BIT4  :
				                                      (enable_master_fsm)                                                          ? MASTER_TX_BIT5  :
																		                                                                           MASTER_INACTIVE;
	         MASTER_TX_BIT4  : master_next_state = (enable_master_fsm && `MASTER_TX_NEXT)                                       ? MASTER_TX_BIT3  :
				                                      (enable_master_fsm)                                                          ? MASTER_TX_BIT4  :
																		                                                                           MASTER_INACTIVE;
	         MASTER_TX_BIT3  : master_next_state = (enable_master_fsm && `MASTER_TX_NEXT)                                       ? MASTER_TX_BIT2  :
				                                      (enable_master_fsm)                                                          ? MASTER_TX_BIT3  :
																		                                                                           MASTER_INACTIVE;
	         MASTER_TX_BIT2  : master_next_state = (enable_master_fsm && `MASTER_TX_NEXT)                                       ? MASTER_TX_BIT1  :
				                                      (enable_master_fsm)                                                          ? MASTER_TX_BIT2  :
																		                                                                           MASTER_INACTIVE;
	         MASTER_TX_BIT1  : master_next_state = (enable_master_fsm && `MASTER_TX_NEXT)                                       ? MASTER_TX_BIT0  :
				                                      (enable_master_fsm)                                                          ? MASTER_TX_BIT1  :
																		                                                                           MASTER_INACTIVE;
	         MASTER_TX_BIT0  : master_next_state = (enable_master_fsm && `MASTER_TX_NEXT)                                       ? MASTER_TX_ACK   :
				                                      (enable_master_fsm)                                                          ? MASTER_TX_BIT0  :
																		                                                                           MASTER_INACTIVE;
	         MASTER_TX_ACK   : master_next_state = (enable_master_fsm && `MASTER_TX_NEXT)                                       ? MASTER_TX_PREP  :
				                                      (enable_master_fsm)                                                          ? MASTER_TX_ACK   :
																		                                                                           MASTER_INACTIVE;
				MASTER_TX_PREP  : master_next_state = (`NEXT_BYTE_VALID  && `MASTER_TX_HIGH && master_type_work_reg == MASTER_S)   ? MASTER_TX_START :
				                                      (`NEXT_BYTE_VALID  && `MASTER_TX_HIGH && master_type_work_reg == MASTER_TX_C)? MASTER_TX_BIT7  :
									   						  (enable_master_fsm && `MASTER_TX_HIGH && master_type_work_reg == MASTER_RX_C)? MASTER_RX_BIT7  :
																  (`THIS_BYTE_VALID  && `MASTER_TX_HIGH && master_type_work_reg == MASTER_P)   ? MASTER_TX_STOP  :
																  (`THIS_BYTE_VALID)                                                           ? MASTER_TX_PREP  :
									   							                                                                              MASTER_INACTIVE;																																										
	         MASTER_TX_STOP  : master_next_state = (enable_master_fsm && !master_tx_wait)                                       ? MASTER_INACTIVE :				                                         
				                                      (enable_master_fsm)                                                          ? MASTER_TX_STOP  :
																	                                                                              MASTER_INACTIVE;	
				MASTER_RX_BIT7	 : master_next_state = (enable_master_fsm && `POSEDGE_DETECT)                                       ? MASTER_RX_BIT6  :
				                                      (enable_master_fsm)                                                          ? MASTER_RX_BIT7  :
																                                                                                 MASTER_INACTIVE;
				MASTER_RX_BIT6	 : master_next_state = (enable_master_fsm && `POSEDGE_DETECT)                                       ? MASTER_RX_BIT5  :
				                                      (enable_master_fsm)                                                          ? MASTER_RX_BIT6  :
																                                                                                 MASTER_INACTIVE;
				MASTER_RX_BIT5	 : master_next_state = (enable_master_fsm && `POSEDGE_DETECT)                                       ? MASTER_RX_BIT4  :
				                                      (enable_master_fsm)                                                          ? MASTER_RX_BIT5  :
																                                                                                 MASTER_INACTIVE;
				MASTER_RX_BIT4	 : master_next_state = (enable_master_fsm && `POSEDGE_DETECT)                                       ? MASTER_RX_BIT3  :
				                                      (enable_master_fsm)                                                          ? MASTER_RX_BIT4  :
																                                                                                 MASTER_INACTIVE;
				MASTER_RX_BIT3	 : master_next_state = (enable_master_fsm && `POSEDGE_DETECT)                                       ? MASTER_RX_BIT2  :
				                                      (enable_master_fsm)                                                          ? MASTER_RX_BIT3  :
									      					                                                                                 MASTER_INACTIVE;
				MASTER_RX_BIT2	 : master_next_state = (enable_master_fsm && `POSEDGE_DETECT)                                       ? MASTER_RX_BIT1  :
				                                      (enable_master_fsm)                                                          ? MASTER_RX_BIT2  :
																                                                                                 MASTER_INACTIVE;
				MASTER_RX_BIT1	 : master_next_state = (enable_master_fsm && `POSEDGE_DETECT)                                       ? MASTER_RX_BIT0  :
				                                      (enable_master_fsm)                                                          ? MASTER_RX_BIT1  :
																                                                                                 MASTER_INACTIVE;
				MASTER_RX_BIT0	 : master_next_state = (enable_master_fsm && `NEGEDGE_DETECT)                                       ? MASTER_RX_ACK   :
				                                      (enable_master_fsm)                                                          ? MASTER_RX_BIT0  :
																                                                                                 MASTER_INACTIVE;
            MASTER_RX_ACK   : master_next_state = (enable_master_fsm && `NEGEDGE_DETECT)                                       ? MASTER_TX_PREP  :
				                                      (enable_master_fsm)                                                          ? MASTER_RX_ACK   :
				                       					                                                                                 MASTER_INACTIVE;
				default         : master_next_state = MASTER_INACTIVE;		  
		  endcase
	 end

endmodule
