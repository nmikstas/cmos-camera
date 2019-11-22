`timescale 1ns / 1ps

module uart(
    input clk,
    input reset,
    input [15:0] id,
    input [15:0] din,
    input write,
    input rx,
    output reg tx = 1'b1,
    output [7:0]dout,
	 output reg [11:0]rxcount = 12'h000,
	 output reg [11:0]txcount = 12'h000
    );
	 
	 parameter initbaud    = 16'd2604; //Default 9600 baud.
	 
	 parameter setBaud     = 16'h0200;
	 parameter txStoreByte = 16'h0201;
	 parameter txFlush     = 16'h0202;
	 parameter txPurge     = 16'h0203;
	 parameter rxNextByte  = 16'h0204;
	 parameter rxPurge     = 16'h0205;
	 
	 parameter TXREADY     = 4'h0;
	 parameter TXSYNC      = 4'h1;
    parameter TXSTART     = 4'h2;
    parameter TXB0        = 4'h3;
    parameter TXB1        = 4'h4;
    parameter TXB2        = 4'h5;
    parameter TXB3        = 4'h6;
    parameter TXB4        = 4'h7;
    parameter TXB5        = 4'h8;
    parameter TXB6        = 4'h9;
    parameter TXB7        = 4'hA;
    parameter TXSTOP      = 4'hB;
	 
	 parameter RXREADY     = 4'h0;
	 parameter RXSTART     = 4'h1;
	 parameter RXB0        = 4'h2;
	 parameter RXB1        = 4'h3;
	 parameter RXB2        = 4'h4;
	 parameter RXB3        = 4'h5;
	 parameter RXB4        = 4'h6;
	 parameter RXB5        = 4'h7;
	 parameter RXB6        = 4'h8;
	 parameter RXB7        = 4'h9;
	 parameter RXSTOP      = 4'hA;
	 parameter RXSTORE     = 4'hB;
	 
	 reg [3:0]txstate      = TXREADY;
	 reg [3:0]txnextstate  = TXREADY;
	 
	 reg [3:0]rxstate      = RXREADY;
	 reg [3:0]rxnextstate  = RXREADY;

    //baudreg calculation is as follows:
	 //Clock frequency / desired baud rate / 2.
    reg [15:0]txbaudreg  = initbaud;
	 reg [17:0]txcountreg = 18'h00000; //Counts system clock cycles to generate baud clock.
	 reg baudclock        = 1'b0;      //Used to time data out.
	 
	 reg [15:0]rxbaudcntr = 16'h0000;
	 
	 reg [10:0]txstartreg = 11'h000;
	 reg [10:0]txendreg   = 11'h000; //Tx buffer regs. 
	 
	 reg [10:0]rxstartreg = 11'h000;
	 reg [10:0]rxendreg   = 11'h000; //Rx buffer regs.
	 
	 reg baudthis        = 1'b0;
	 reg baudlast        = 1'b0;
	 reg baudpostrans    = 1'b0;
	 
	 reg rxthis          = 1'b0;
	 reg rxlast          = 1'b0;
	 reg rxnegtrans      = 1'b0;
	 
	 reg nbwait          = 1'b0; //Wait while user retrieves received byte.
	 
	 reg [7:0]txreg = 8'h00;
	 reg [7:0]rxreg = 8'h00;

	 wire txwe;
	 wire rxwe;	 
	 
	 wire [7:0]txdout;
	 
	 RAMB16_S9_S9 #(
      .INIT_A(9'h000),              // Value of output RAM registers on Port A at startup
      .INIT_B(9'h000),              // Value of output RAM registers on Port B at startup
      .SRVAL_A(9'h000),             // Port A output value upon SSR assertion
      .SRVAL_B(9'h000),             // Port B output value upon SSR assertion
      .WRITE_MODE_A("WRITE_FIRST"), // WRITE_FIRST, READ_FIRST or NO_CHANGE
      .WRITE_MODE_B("WRITE_FIRST"), // WRITE_FIRST, READ_FIRST or NO_CHANGE
      .SIM_COLLISION_CHECK("ALL"))  // "NONE", "WARNING_ONLY", "GENERATE_X_ONLY", "ALL" 
    TXRAM (
      .DOA(txdout),                 // Port A 8-bit Data Output
      .DOB(),                       // Port B 16-bit Data Output
      .ADDRA(txstartreg),           // Port A 11-bit Address Input
      .ADDRB(txendreg),             // Port B 11-bit Address Input
      .CLKA(clk),                   // Port A Clock
      .CLKB(clk),                   // Port B Clock
      .DIA(),                       // Port A 8-bit Data Input
      .DIB(din[7:0]),               // Port-B 8-bit Data Input
		.DIPA(1'b0),                // Port A 1-bit parity Input
		.DIPB(1'b0),                // Port B 1-bit parity Input
      .ENA(1'b1),                   // Port A RAM Enable Input
      .ENB(1'b1),                   // Port B RAM Enable Input
      .SSRA(1'b0),                  // Port A Synchronous Set/Reset Input
      .SSRB(1'b0),                  // Port B Synchronous Set/Reset Input
      .WEA(1'b0),                   // Port A Write Enable Input
      .WEB(txwe)                    // Port B Write Enable Input
    );
	 
	 RAMB16_S9_S9 #(
      .INIT_A(9'h000),              // Value of output RAM registers on Port A at startup
      .INIT_B(9'h000),              // Value of output RAM registers on Port B at startup
      .SRVAL_A(9'h000),             // Port A output value upon SSR assertion
      .SRVAL_B(9'h000),             // Port B output value upon SSR assertion
      .WRITE_MODE_A("WRITE_FIRST"), // WRITE_FIRST, READ_FIRST or NO_CHANGE
      .WRITE_MODE_B("WRITE_FIRST"), // WRITE_FIRST, READ_FIRST or NO_CHANGE
      .SIM_COLLISION_CHECK("ALL"))  // "NONE", "WARNING_ONLY", "GENERATE_X_ONLY", "ALL" 
    RXRAM (
      .DOA(),                       // Port A 8-bit Data Output
      .DOB(dout),                   // Port B 16-bit Data Output
      .ADDRA(rxendreg),             // Port A 11-bit Address Input
      .ADDRB(rxstartreg),           // Port B 11-bit Address Input
      .CLKA(clk),                   // Port A Clock
      .CLKB(clk),                   // Port B Clock
      .DIA(rxreg),                  // Port A 8-bit Data Input
      .DIB(),                       // Port-B 8-bit Data Input
		.DIPA(1'b0),                // Port A 1-bit parity Input
		.DIPB(1'b0),                // Port B 1-bit parity Input
      .ENA(1'b1),                   // Port A RAM Enable Input
      .ENB(1'b1),                   // Port B RAM Enable Input
      .SSRA(1'b0),                  // Port A Synchronous Set/Reset Input
      .SSRB(1'b0),                  // Port B Synchronous Set/Reset Input
      .WEA(rxwe),                   // Port A Write Enable Input
      .WEB(1'b0)                    // Port B Write Enable Input
    );
	 
	 assign txwe   = (write && id == txStoreByte) ? 1'b1 : 1'b0;	 
	 assign rxwe   = (rxstate == RXSTOP) ? 1'b1 : 1'b0;
	 
	 always @(posedge clk) begin
	     txcountreg <= txcountreg + 1'b1;
		  txstate    <= txnextstate;
		  rxstate    <= rxnextstate;
		  
		  //Keep track of baud clock edges.
		  baudthis <= baudclock;
		  baudlast <= baudthis;
		  
		  //Keep track of rx edges
		  rxthis   <= rx;
		  rxlast   <= rxthis;
		  
		  //Keep track of rx negative edge.
		  if(rxlast && !rxthis)
		      rxnegtrans <= 1'b1;
		  else
		      rxnegtrans <= 1'b0;
		  
		  //Keep track of baud clock positive edge.
		  if(!baudlast && baudthis)
		      baudpostrans <= 1'b1;
		  else
		      baudpostrans <= 1'b0;
		  
		  //Reset all registers to defaults.
		  if(reset) begin 	  
				txcountreg  <= 18'h00000;
				rxstartreg  <= 11'h000;	         
			   txstartreg  <= 11'h000;
				txbaudreg   <= initbaud;
				baudclock   <= 1'b0;				
	         txendreg    <= 11'h000;                        
            rxendreg    <= 11'h000;
				txstate     <= TXREADY;
				rxstate     <= RXREADY;
				txcount     <= 10'h000;
            rxcount     <= 10'h000;
            txreg       <= 8'h00;
            rxreg       <= 8'h00;		
            tx          <= 1'b1;				
		  end
		  
		  if(txstate == TXREADY || txstate == TXSYNC)
		      tx <= 1'b1;	
		  
		  if(txcountreg == txbaudreg) begin
		      baudclock  <= ~baudclock;
		  		txcountreg <= 18'h00000;
		  end

        if(id == setBaud && write)
		      txbaudreg <= din;
				
		  if(id == txStoreByte && write) begin
				txendreg <= txendreg + 1;
				if(txcount < 2048) //Still room in buffer.
				    txcount <= txcount + 1;
				else //No room in buffer.  Overwrite oldest byte.
				    txstartreg <= txstartreg + 1;				
		  end
		  
		  if(nbwait) begin
		      rxstartreg <= rxstartreg + 1;
				rxcount    <= rxcount - 1;
				nbwait     <= nbwait + 1;
		  end
			
		  if(id == rxNextByte && write && rxcount) begin
		      nbwait <= 1'b1;				
		  end
		  
		  if(id == txPurge && write) begin
		      txendreg   <= 0;
				txstartreg <= 0;
				txcount    <= 0;
		  end
		  
		  if(id == rxPurge && write) begin
		      rxendreg   <= 0;
				rxstartreg <= 0;
				rxcount    <= 0;
		  end

        if(txstate == TXSTART) begin
		      txreg <= txdout;
				tx <= 1'b0;
		  end
		  
		  if(txstate == TXB0)
		      tx <= txreg[0];
				
		  if(txstate == TXB1)
		      tx <= txreg[1];
				
		  if(txstate == TXB2)
		      tx <= txreg[2];
				
		  if(txstate == TXB3)
		      tx <= txreg[3];
				
		  if(txstate == TXB4)
		      tx <= txreg[4];
		  
		  if(txstate == TXB5)
		      tx <= txreg[5];
		  
		  if(txstate == TXB6)
		      tx <= txreg[6];
				
		  if(txstate == TXB7)
		      tx <= txreg[7];
				
		  if(txstate == TXSTOP) begin
		      tx <= 1'b1;
				
			end
		  
		  if(txnextstate == TXSTOP && baudpostrans) begin
		      txcount  <= txcount  - 1;
				txstartreg <= txstartreg + 1;
		  end	

	     if(rxbaudcntr)
		      rxbaudcntr <= rxbaudcntr - 1;
	 
	     if(rxstate == RXREADY && rxnextstate == RXSTART)
		      rxbaudcntr <= txbaudreg * 2 + txbaudreg;
			
		  if(rxstate == RXSTART && rxnextstate == RXB0) begin
		      rxreg[0]   <= rx;
		      rxbaudcntr <= txbaudreg * 2;
		  end
		  
		  if(rxstate == RXB0 && rxnextstate == RXB1) begin
		      rxreg[1]   <= rx;
		      rxbaudcntr <= txbaudreg * 2;
		  end
		  
		  if(rxstate == RXB1 && rxnextstate == RXB2) begin
		      rxreg[2]   <= rx;
		      rxbaudcntr <= txbaudreg * 2;
		  end
		  
		  if(rxstate == RXB2 && rxnextstate == RXB3) begin
		      rxreg[3]   <= rx;
		      rxbaudcntr <= txbaudreg * 2;
		  end
		  
		  if(rxstate == RXB3 && rxnextstate == RXB4) begin
		      rxreg[4]   <= rx;
		      rxbaudcntr <= txbaudreg * 2;
		  end
		  
		  if(rxstate == RXB4 && rxnextstate == RXB5) begin
		      rxreg[5]   <= rx;
		      rxbaudcntr <= txbaudreg * 2;
		  end
		  
		  if(rxstate == RXB5 && rxnextstate == RXB6) begin
		      rxreg[6]   <= rx;
		      rxbaudcntr <= txbaudreg * 2;
		  end
		  
		  if(rxstate == RXB6 && rxnextstate == RXB7) begin
		      rxreg[7]   <= rx;
		      rxbaudcntr <= txbaudreg * 2;
		  end
		  
		  if(rxstate == RXSTOP && rxnextstate == RXSTORE) begin
	         rxendreg <= rxendreg + 1;
				if(rxcount < 1024)
				    rxcount  <= rxcount  + 1;
	     end		  
	 end
	 
    always @(*) begin //Transmit finite state machine.
	     case(txstate)
            TXREADY : txnextstate = reset ? TXREADY :
				                        (id == txFlush && write && txcount) ? TXSYNC :
												TXREADY;
			   TXSYNC  : txnextstate = baudpostrans ? TXSTART : TXSYNC;
            TXSTART : txnextstate = baudpostrans ? TXB0    : TXSTART;
            TXB0    : txnextstate = baudpostrans ? TXB1    : TXB0;
            TXB1    : txnextstate = baudpostrans ? TXB2    : TXB1;
            TXB2    : txnextstate = baudpostrans ? TXB3    : TXB2;
            TXB3    : txnextstate = baudpostrans ? TXB4    : TXB3;
            TXB4    : txnextstate = baudpostrans ? TXB5    : TXB4;
            TXB5    : txnextstate = baudpostrans ? TXB6    : TXB5;
            TXB6    : txnextstate = baudpostrans ? TXB7    : TXB6;
            TXB7    : txnextstate = baudpostrans ? TXSTOP  : TXB7;
            TXSTOP  : txnextstate = (baudpostrans && txcount) ? TXSTART : 
				                        baudpostrans ? TXREADY :
												TXSTOP;
	 	  endcase
	 end
	 
	 always @(*) begin //Receive finite state machine.
	     case(rxstate)
		      RXREADY : rxnextstate = rxnegtrans ? RXSTART : RXREADY;
				RXSTART : rxnextstate = rxbaudcntr ? RXSTART : RXB0;
				RXB0    : rxnextstate = rxbaudcntr ? RXB0    : RXB1;
				RXB1    : rxnextstate = rxbaudcntr ? RXB1    : RXB2;
				RXB2    : rxnextstate = rxbaudcntr ? RXB2    : RXB3;
				RXB3    : rxnextstate = rxbaudcntr ? RXB3    : RXB4;
				RXB4    : rxnextstate = rxbaudcntr ? RXB4    : RXB5;
				RXB5    : rxnextstate = rxbaudcntr ? RXB5    : RXB6;
				RXB6    : rxnextstate = rxbaudcntr ? RXB6    : RXB7;
				RXB7    : rxnextstate = rxbaudcntr ? RXB7    : RXSTOP;
				RXSTOP  : rxnextstate = RXSTORE;
				RXSTORE : rxnextstate = RXREADY;
		  endcase	 
	 end

endmodule
