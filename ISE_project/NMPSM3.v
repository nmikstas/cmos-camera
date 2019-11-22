`timescale 1ns / 1ps

module NMPSM3(clk, reset, INSTRUCTION, IN_PORT, IRQ0, IRQ1, IRQ2, IRQ3,
              ADDRESS, OUT_PORT, PORT_ID, READ_STROBE, WRITE_STROBE, 
				  IRQ_ACK0, IRQ_ACK1, IRQ_ACK2, IRQ_ACK3);

    input  clk, reset, IRQ0, IRQ1, IRQ2, IRQ3;
	 input  [35:0]INSTRUCTION;
	 input  [15:0]IN_PORT;
	 output READ_STROBE, WRITE_STROBE, IRQ_ACK0, IRQ_ACK1, IRQ_ACK2, IRQ_ACK3;
	 output [15:0]PORT_ID;
	 output [15:0]OUT_PORT;
	 output [15:0]ADDRESS;
	 
	 localparam SIZE = 16;
	 
	 localparam JPNZ = 8'h16;
	 localparam JPZ  = 8'h19;
	 localparam JPNC = 8'h1C;
	 localparam JPC  = 8'h20;
	 
	 localparam CLNZ = 8'h29;
	 localparam CLZ  = 8'h2C;
	 localparam CLNC = 8'h30;
	 localparam CLC  = 8'h33;
	 
	 localparam RTNZ = 8'h39;
	 localparam RTZ  = 8'h3C;
	 localparam RTNC = 8'h40;
	 localparam RTC  = 8'h43;	 
	 
	 localparam IRQADDR0 = 8'hCC;
	 localparam IRQADDR1 = 8'hD0;
	 localparam IRQADDR2 = 8'hD3;
	 localparam IRQADDR3 = 8'hD6;
	 
	 localparam STEP = 8'hD9;
	 
	 wire [43:0]control;
	 wire [15:0]portA;
	 wire [15:0]portB;	
	 wire zero;
	 wire [7:0]decodeAddr;
	 wire I0, I1, I2, I3;
	 wire [15:0]addrp1;
	 wire [10:0] addrA;
    wire [15:0] dataA;
    wire weA;
    wire [10:0] addrB;
    wire [15:0] dataB;
    wire weB;
	 wire [9:0]stackm1;
	 wire [19:0]none;
	 wire [7:0]portAup;
	 wire [7:0]portAdn;
	 wire [7:0]portBup;
	 wire [7:0]portBdn;
	 wire [4:0]sel;
    wire [15:0]a;
	 wire [15:0]b;
	 wire [15:0]inst;
	 
	 reg [1:0]IRQload = 2'b00;
	 reg [15:0]wresult = 16'h0000;
	 reg wcarry = 1'b0;	 
	 reg [15:0]result  = 16'h0000;
	 reg carry  = 1'b0;
	 reg [1:0]load = 2'b00; 
	 reg IRQMreg = 1'b1;
	 reg IRQ0reg = 1'b0;
	 reg IRQ1reg = 1'b0;
	 reg IRQ2reg = 1'b0;
	 reg IRQ3reg = 1'b0;
	 reg [9:0]stack = 10'h000;
	 reg [15:0]addr = 16'h0000;
	 
	 //Used to synchronize interrupts and reset with internal clock.
	 reg IR0 = 1'b0;
	 reg IR1 = 1'b0;
	 reg IR2 = 1'b0;
	 reg IR3 = 1'b0;
	 reg [1:0]rst = 2'b00;

    RAMB16_S36_S36 #(
      .INIT_A(36'h000000000),       // Value of output RAM registers on Port A at startup
      .INIT_B(36'h000000000),       // Value of output RAM registers on Port B at startup
      .SRVAL_A(36'h000000000),      // Port A output value upon SSR assertion
      .SRVAL_B(36'h000000000),      // Port B output value upon SSR assertion
      .WRITE_MODE_A("WRITE_FIRST"), // WRITE_FIRST, READ_FIRST or NO_CHANGE
      .WRITE_MODE_B("WRITE_FIRST"), // WRITE_FIRST, READ_FIRST or NO_CHANGE
      .SIM_COLLISION_CHECK("ALL"),  // "NONE", "WARNING_ONLY", "GENERATE_X_ONLY", "ALL" 

      // Micro-code for the decoder ROM
      .INIT_00(256'H00200001_00000000_00000000_04040007_00000000_00000000_04000007_00000000),
      .INIT_01(256'H00000000_08200007_00000001_00000000_00000000_08000007_00000000_04040007),
      .INIT_02(256'H00000000_0000000B_00000000_00000000_0000000F_00000000_00000000_0000000B),
      .INIT_03(256'H00000000_00000000_00000000_0000000B_00000000_00000000_0000000B_00000000),
      .INIT_04(256'H00000000_1950000F_00000000_00000000_1950000B_00000000_00000000_0000000B),
      .INIT_05(256'H00000000_00000000_00000000_1950000B_00000000_00000000_1950000B_00000000),
      .INIT_06(256'H00000017_12300001_00000000_00000000_1950000B_00000000_00000000_1950000B),
      .INIT_07(256'H00000000_00000000_00000017_12300001_00000000_00000017_12300001_00000000),
      .INIT_08(256'H00001137_12300001_00000000_00000017_12300001_00000000_00000017_12300001),
      .INIT_09(256'H00000000_00000000_00000000_44080407_00000000_00001157_12300001_00000000),
      .INIT_0A(256'H00000000_20000A07_00000000_00000000_20000C07_00000000_00000000_44080207),
      .INIT_0B(256'H00000000_00000000_00000000_04065007_00000000_00000000_04064007_00000000),
      .INIT_0C(256'H00000000_04066007_00000000_00000000_04063007_00000000_00000000_04062007),
      .INIT_0D(256'H00000000_00000000_00000000_0406C007_00000000_00000000_04067007_00000000),
      .INIT_0E(256'H00000000_04069007_00000000_00000000_0406D007_00000000_00000000_04068007),
      .INIT_0F(256'H00000000_00000000_00000000_0406A007_00000000_00000000_0406E007_00000000),
      .INIT_10(256'H00000000_00010007_00000000_00000000_0406B007_00000000_00000000_0406F007),
      .INIT_11(256'H00000000_00000000_00000000_00012007_00000000_00000000_00011007_00000000),
      .INIT_12(256'H00000000_04075007_00000000_00000000_04074007_00000000_00000000_00013007),
      .INIT_13(256'H00000000_00000000_00000000_04077007_00000000_00000000_04076007_00000000),
      .INIT_14(256'H00000000_00000027_00000000_00000000_00018007_00000000_00000000_00019007),
      .INIT_15(256'H00000000_00000000_00000000_00000067_00000000_00000000_00000047_00000000),
      .INIT_16(256'H00000000_000000C7_00000000_00000000_000000A7_00000000_00000000_00000087),
      .INIT_17(256'H00000000_00000000_00000000_00000107_00000000_00000000_000000E7_00000000),
      .INIT_18(256'H04040007_12300001_00000000_00000000_00000000_00000000_00000000_19100007),
      .INIT_19(256'H00000000_00000000_80000013_99900161_00000000_00000000_00000000_00000000),
      .INIT_1A(256'H00000013_19900161_00000000_00000013_19900161_00000000_00000013_19900161),
      .INIT_1B(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000007_00000000),
      .INIT_1C(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_1D(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_1E(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_1F(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_20(256'H00000080_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_21(256'H00000000_00000000_000000E0_00000000_00000000_00000000_00000000_00000000),
      .INIT_22(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_23(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_24(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_25(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_26(256'H00000000_00000370_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_27(256'H00000000_00000000_00000000_000003D0_00000000_00000000_000003A0_00000000),
      .INIT_28(256'H00000000_00000470_00000000_00000000_00000440_00000000_00000000_00000410),
      .INIT_29(256'H00000000_00000000_00000000_00000000_00000000_00000000_000004A0_00000000),
      .INIT_2A(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_2B(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_2C(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_2D(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_2E(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_2F(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_30(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_31(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_32(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_33(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_34(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_35(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_36(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_37(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_38(256'H00000000_00000C70_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_39(256'H00000000_00000000_00000000_00000CD8_00000000_00000000_00000000_00000000),
      .INIT_3A(256'H00000004_00000D6C_00000000_00000002_00000D4A_00000000_00000001_00000D19),
      .INIT_3B(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_3C(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_3D(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_3E(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000),
      .INIT_3F(256'H00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000))
    DecoderROM (
      .DOA(control[31:0]),          // Port A 32-bit Data Output
      .DOB({none, control[43:32]}), // Port B 32-bit Data Output
      .ADDRA({1'b0, decodeAddr}),   // Port A 9-bit Address Input
      .ADDRB({1'b1, decodeAddr}),   // Port B 9-bit Address Input
      .CLKA(clk),                   // Port A Clock
      .CLKB(clk),                   // Port B Clock
      .ENA(1'b1),                   // Port A RAM Enable Input
      .ENB(1'b1),                   // Port B RAM Enable Input
      .SSRA(1'b0),                  // Port A Synchronous Set/Reset Input
      .SSRB(1'b0),                  // Port B Synchronous Set/Reset Input
      .WEA(1'b0),                   // Port A Write Enable Input
      .WEB(1'b0)                    // Port B Write Enable Input
    );
	
    RAMB16_S9_S9 #(
      .INIT_A(18'h00000),           // Value of output RAM registers on Port A at startup
      .INIT_B(18'h00000),           // Value of output RAM registers on Port B at startup
      .SRVAL_A(18'h00000),          // Port A output value upon SSR assertion
      .SRVAL_B(18'h00000),          // Port B output value upon SSR assertion
      .WRITE_MODE_A("WRITE_FIRST"), // WRITE_FIRST, READ_FIRST or NO_CHANGE
      .WRITE_MODE_B("WRITE_FIRST"), // WRITE_FIRST, READ_FIRST or NO_CHANGE
      .SIM_COLLISION_CHECK("ALL"))  // "NONE", "WARNING_ONLY", "GENERATE_X_ONLY", "ALL" 
    RAMupper (
      .DOA(portAup),                // Port A 16-bit Data Output
      .DOB(portBup),                // Port B 16-bit Data Output
      .ADDRA(addrA),                // Port A 10-bit Address Input
      .ADDRB(addrB),                // Port B 10-bit Address Input
      .CLKA(clk),                   // Port A Clock
      .CLKB(clk),                   // Port B Clock
      .DIA(dataA[15:8]),            // Port A 16-bit Data Input
      .DIB(dataB[15:8]),            // Port-B 16-bit Data Input
		.DIPA(1'b0),                  // Port A 1-bit parity Input
		.DIPB(1'b0),                  // Port B 1-bit parity Input
      .ENA(1'b1),                   // Port A RAM Enable Input
      .ENB(1'b1),                   // Port B RAM Enable Input
      .SSRA(1'b0),                  // Port A Synchronous Set/Reset Input
      .SSRB(1'b0),                  // Port B Synchronous Set/Reset Input
      .WEA(weA),                    // Port A Write Enable Input
      .WEB(weB)                     // Port B Write Enable Input
    );
	
    RAMB16_S9_S9 #(
      .INIT_A(18'h00000),           // Value of output RAM registers on Port A at startup
      .INIT_B(18'h00000),           // Value of output RAM registers on Port B at startup
      .SRVAL_A(18'h00000),          // Port A output value upon SSR assertion
      .SRVAL_B(18'h00000),          // Port B output value upon SSR assertion
      .WRITE_MODE_A("WRITE_FIRST"), // WRITE_FIRST, READ_FIRST or NO_CHANGE
      .WRITE_MODE_B("WRITE_FIRST"), // WRITE_FIRST, READ_FIRST or NO_CHANGE
      .SIM_COLLISION_CHECK("ALL"))  // "NONE", "WARNING_ONLY", "GENERATE_X_ONLY", "ALL" 
    RAMlower (
      .DOA(portAdn),                // Port A 16-bit Data Output
      .DOB(portBdn),                // Port B 16-bit Data Output
      .ADDRA(addrA),                // Port A 10-bit Address Input
      .ADDRB(addrB),                // Port B 10-bit Address Input
      .CLKA(clk),                   // Port A Clock
      .CLKB(clk),                   // Port B Clock
      .DIA(dataA[7:0]),             // Port A 16-bit Data Input
      .DIB(dataB[7:0]),             // Port-B 16-bit Data Input
		.DIPA(1'b0),                  // Port A 1-bit parity Input
		.DIPB(1'b0),                  // Port B 1-bit parity Input
      .ENA(1'b1),                   // Port A RAM Enable Input
      .ENB(1'b1),                   // Port B RAM Enable Input
      .SSRA(1'b0),                  // Port A Synchronous Set/Reset Input
      .SSRB(1'b0),                  // Port B Synchronous Set/Reset Input
      .WEA(weA),                    // Port A Write Enable Input
      .WEB(weB)                     // Port B Write Enable Input
    );
	 
	 always @(posedge clk) begin
	     if(rst) begin
				carry   <= 1'b0;
				IRQMreg <= 1'b1;
				IRQ0reg <= 1'b0;
				IRQ1reg <= 1'b0;
				IRQ2reg <= 1'b0;
				IRQ3reg <= 1'b0;
				stack   <= 10'h000;
				result  <= 16'h0000;
				addr    <= 16'h0000;
				load    <= 2'b00;
            rst <= rst + 1'b1;				
	     end	     
		  else begin
		      result <= wresult;
				carry  <= wcarry;
				if(control[1])
			       addr  <= ADDRESS;
		      if(control[25:24] == 2'b01)
		          stack <= stack + 1'b1;
		      if(control[25:24] == 2'b10)
		          stack <= stack - 1'b1;
		      if(control[8:5] == 4'b0001)
		          IRQ0reg <=1'b1;
		      if(control[8:5] == 4'b0010)
		          IRQ1reg <=1'b1;
	         if(control[8:5] == 4'b0011)
		          IRQ2reg <=1'b1;
	         if(control[8:5] == 4'b0100)
		          IRQ3reg <=1'b1;
	         if(control[8:5] == 4'b0101)
		          IRQ0reg <=1'b0;
		      if(control[8:5] == 4'b0110)
		          IRQ1reg <=1'b0;
		      if(control[8:5] == 4'b0111)
		          IRQ2reg <=1'b0;
            if(control[8:5] == 4'b1000)
		          IRQ3reg <=1'b0;	
            if(control[8:5] == 4'b1001)
		          IRQMreg <=1'b1;
		      if(control[8:5] == 4'b1010) begin
		          IRQMreg <= 1'b1;
				    IRQ0reg <= 1'b0;
				    IRQ1reg <= 1'b0;
				    IRQ2reg <= 1'b0;
				    IRQ3reg <= 1'b0;
				end
				if(control[8:5] == 4'b1011)
				    IRQMreg <= 1'b0;
				if(control[35])
				    load <= {carry, ~zero};
				//Synchronize interrupts and reset with the internal clock.	 
            if(IRQ0) 
				    IR0 <= 1'b1;
		      else
				    IR0 <= 1'b0;
		      if(IRQ1)
				    IR1 <= 1'b1;
		      else   
				    IR1 <= 1'b0;
		      if(IRQ2) 
				    IR2 <= 1'b1;
		      else   
				    IR2 <= 1'b0;
		      if(IRQ3) 
				    IR3 <= 1'b1;
		      else   
				    IR3 <= 1'b0;
            if (reset)
                rst <= 2'b01;				
        end 
	 end
	 
	 assign IRQ_ACK0 = control[31];
	 assign IRQ_ACK1 = control[32];
	 assign IRQ_ACK2 = control[33];
	 assign IRQ_ACK3 = control[34];
	 
	 always @(control)
	     case(control[33:31])
		      3'b001  : IRQload <= 2'h1;
				3'b010  : IRQload <= 2'h2;
				3'b100  : IRQload <= 2'h3;
				default : IRQload <= 2'h4;
        endcase
	 
	 and andIRQ0 (I0, IRQMreg, IRQ0reg, IR0);
	 and andIRQ1 (I1, IRQMreg, IRQ1reg, IR1);
	 and andIRQ2 (I2, IRQMreg, IRQ2reg, IR2);
	 and andIRQ3 (I3, IRQMreg, IRQ3reg, IR3);
	 
	 assign decodeAddr = control[0] ? control[43:36] :	                     
                        ({control[0], I0}             == 2'b01)    ? IRQADDR0 :
	                     ({control[0], I0, I1}         == 3'b001)   ? IRQADDR1 :
								({control[0], I0, I1, I2}     == 4'b0001)  ? IRQADDR2 :
								({control[0], I0, I1, I2, I3} == 5'b00001) ? IRQADDR3 :
								({zero,  INSTRUCTION[35:28]}  == {1'b1, JPNZ}) ? STEP :
								({zero,  INSTRUCTION[35:28]}  == {1'b0, JPZ }) ? STEP :
								({carry, INSTRUCTION[35:28]}  == {1'b1, JPNC}) ? STEP :
								({carry, INSTRUCTION[35:28]}  == {1'b0, JPC }) ? STEP :
								({zero,  INSTRUCTION[35:28]}  == {1'b1, CLNZ}) ? STEP :
								({zero,  INSTRUCTION[35:28]}  == {1'b0, CLZ }) ? STEP :
								({carry, INSTRUCTION[35:28]}  == {1'b1, CLNC}) ? STEP :
								({carry, INSTRUCTION[35:28]}  == {1'b0, CLC }) ? STEP :
								({zero,  INSTRUCTION[35:28]}  == {1'b1, RTNZ}) ? STEP :
								({zero,  INSTRUCTION[35:28]}  == {1'b0, RTZ }) ? STEP :
								({carry, INSTRUCTION[35:28]}  == {1'b1, RTNC}) ? STEP :
								({carry, INSTRUCTION[35:28]}  == {1'b0, RTC }) ? STEP :
	                     INSTRUCTION[35:28];

    assign PORT_ID  = (control[10:9] == 2'b01) ? portB             :
	                   (control[10:9] == 2'b10) ? INSTRUCTION[15:0] :
						    16'h0000;
							 
    assign OUT_PORT = (control[11] == 1'b1) ? portA : 16'h0000;
							
	 assign WRITE_STROBE = control[29];
	 
	 assign READ_STROBE  = control[30];
	 
	 assign stackm1 = stack - 1'b1;
	 
	 assign weA = control[26];
	 assign weB = control[27];
	 
	 assign addrA = {1'b0, INSTRUCTION[25:16]};
	 
	 assign portA = {portAup, portAdn};
	 
	 assign portB = {portBup, portBdn};
	 	 
	 assign dataA = (control[19:17] == 3'b001) ? portA    :
	                (control[19:17] == 3'b010) ? portB    :
						 (control[19:17] == 3'b011) ? wresult  :
						 (control[19:17] == 3'b100) ? IN_PORT  :
	                INSTRUCTION[15:0];
						 
	 assign addrB = (control[21:20] == 2'b01) ? {control[28], stack[9:0]}   :
	                (control[21:20] == 2'b10) ? {control[28], portB[9:0]}   :
	 					 (control[21:20] == 2'b11) ? {control[28], stackm1[9:0]} :
	                {control[28], INSTRUCTION[9:0]};
						 
    assign dataB = (control[23:22] == 2'b01) ? addrp1  :
	                (control[23:22] == 2'b10) ? ADDRESS :
	                portA;

    assign addrp1 = addr + 1'b1;
	 
	 assign ADDRESS = rst ? 16'h0000 :
	                  (control[4:2] == 3'b001) ? addrp1            :
	   				   (control[4:2] == 3'b010) ? INSTRUCTION[15:0] :
	   					(control[4:2] == 3'b011) ? portA             :
							(control[4:2] == 3'b100) ? {14'h0000,IRQload}:
							(control[4:2] == 3'b101) ? portB             :
							addr;
							
    //ALU code begins here.
    assign zero = (result == 16'h0000) ? 1'b1 : 1'b0;
							
	 assign inst = INSTRUCTION[15:0];
	 assign a = portA;
	 assign b = portB;
	 assign sel = control[16:12];
	 
	 //OR a | b, a | inst
	 wire orc; 
	 wire [15:0]orr;
	 
	 assign orc  = 1'b0;	 
    assign orr  = sel[0] ? (a | b) : (a | inst);
	 
	 //AND  a & b, a & inst
	 wire andc;
	 wire [15:0]andr;
	 
	 assign andc = 1'b0;	 
    assign andr = sel[0] ? (a & b) : (a & inst);
	 
	 //XOR  a ^ b, a ^ inst
    wire xorc;
	 wire [15:0]xorr;
	 
	 assign xorc = 1'b0;	 
    assign xorr = sel[0] ? (a ^ b) : (a ^ inst);

    //ADD  ADD a + b, ADDC a + b
    wire addbcarryin, addbcarryout;
	 wire [15:0]addbresult;
	 
	 assign addbcarryin = sel[0] ? carry : 1'b0;	 
    assign {addbcarryout, addbresult} = a + b + addbcarryin;

    //SUB  SUB a - b, SUBC a - b
    wire subbcarryin, subbcarryout;
	 wire [15:0]subbresult;
	 
	 assign subbcarryin = sel[0] ? carry : 1'b0;	 
    assign {subbcarryout, subbresult} = a - b - subbcarryin;

    //ADD  ADD a + inst, ADDC a + inst
    wire addicarryin, addicarryout;
	 wire [15:0]addiresult;
	 
	 assign addicarryin = sel[0] ? carry : 1'b0;	 
    assign {addicarryout, addiresult} = a + inst + addicarryin;

    //SUB  SUB a - inst, SUBC a - inst
    wire subicarryin, subicarryout;
	 wire [15:0]subiresult;

	 assign subicarryin = sel[0] ? carry : 1'b0;	 
    assign {subicarryout, subiresult} = a - inst - subicarryin;

    //TEST  TEST a and b, TEST a and inst  
    wire testc;
	 wire [15:0]testr;
	 
	 assign testc = ^testr;
    assign testr = sel[0] ?  (a & b) :  (a & inst);

    //COMP  COMP a to b, COMP a to inst
    wire tempc1, tempc2, compc;
	 wire [15:0]compr;
	 
	 assign tempc1 = (a < inst) ? 1'b1 : 1'b0;
	 assign tempc2 = (a < b)    ? 1'b1 : 1'b0;

    assign compc   = sel[0] ? tempc2  : tempc1;
	 assign compr   = sel[0] ? (a ^ b) : (a ^ inst);

    //LEFT  ROL, ASL
    wire leftc;
	 wire [15:0]leftr;

    assign leftc = a[15];
	 assign leftr = sel[0] ? {a[14:0], carry} : {a[14:0], 1'b0};

    //RIGHT ROR, LSR
    wire rightc;
	 wire [15:0]rightr;

	 assign rightc = a[0];
	 assign rightr = sel[0] ? {carry, a[15:1]} : {1'b0, a[15:1]};
	 
    //CARRY SETC, CLRC
    wire carryc;
	 wire [15:0]carryr;
	 	 
    assign carryc = sel[0];
	 assign carryr = result;

    //LOAD  LOAD carry and result with load, no change.
	 wire loadc;
	 wire [15:0]loadr;
	 
	 assign loadc = sel[0] ? load[1]              : carry;
	 assign loadr = sel[0] ? {15'h0000,  load[0]} : result;					 
	 
    //MUX results
    always @(*)
        case(sel[4:1])
            4'b0000 : wresult <= loadr;
				4'b0001 : wresult <= orr;
				4'b0010 : wresult <= andr;
				4'b0011 : wresult <= xorr;
				4'b0100 : wresult <= addbresult;
				4'b0101 : wresult <= subbresult;
				4'b0110 : wresult <= addiresult;
				4'b0111 : wresult <= subiresult;
				4'b1000 : wresult <= testr;
				4'b1001 : wresult <= compr;
				4'b1010 : wresult <= leftr;
				4'b1011 : wresult <= rightr;
				4'b1100 : wresult <= carryr;
				default : wresult <= loadr;
        endcase
		  
    always @(*)
        case(sel[4:1])
            4'b0000 : wcarry <= loadc;
				4'b0001 : wcarry <= orc;
				4'b0010 : wcarry <= andc;
				4'b0011 : wcarry <= xorc;
				4'b0100 : wcarry <= addbcarryout;
				4'b0101 : wcarry <= subbcarryout;
				4'b0110 : wcarry <= addicarryout;
				4'b0111 : wcarry <= subicarryout;
				4'b1000 : wcarry <= testc;
				4'b1001 : wcarry <= compc;
				4'b1010 : wcarry <= leftc;
				4'b1011 : wcarry <= rightc;
				4'b1100 : wcarry <= carryc;
				default : wcarry <= loadc;
        endcase

endmodule
