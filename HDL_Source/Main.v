`timescale 1ns / 1ps

module Main(
    input clk,				//Main clock input.
	 input clk25MHz,
	 
	 input btn,
	 
	 //Cellular RAM.
	 output LB,   			//Constantly enable output lower byte.  
	 output UB,  			//Constantly enable output upper byte.
	 output OE,				//Output enable.
	 output WE,				//Write enable.
	 output ADV,			//Address enable.
	 output CE,				//Chip enable.
	 output CRE,			//Control register enable.
	 output RAM_CLK, 		//Clock.
	 input  O_WAIT,  		//Wait signal.
    output [22:0]A,			//Address.
	 inout  [15:0]DQ,		//Data.
	 
	 //VGA controller.
	 output [15:0]vga,
	 output hsync,
	 output vsync,
	 
	 //I2C controller.
	 inout camsda,          //I2C data line.
	 inout camscl,          //I2C clock line.
	 
	 //UART controller.
	 input  rx,
	 output tx,
	 
	 //Camera.
	 input  [9:2]camdata,   //Camera output data.
	 input  camhorz,        //Camera horizontal timing signal.
	 input  camvert,        //Camera vertical timing signal.
	 input  pclk,           //Output pixel clock from camera.
	 output xclk            //Input clock to camera.
    );
	 
	 PULLUP PULLUP_sda (.O(camsda));
	 PULLUP PULLUP_scl (.O(camscl));	 
	 /*********************************************************************************************/
	 
	 //NMPSM3.
	 wire ack0;             //ack for IRQ 0.
	 wire ack1;             //ack for IRQ 0.
	 wire ack2;             //ack for IRQ 0.
	 wire ack3;             //ack for IRQ 0.
	 wire sigout0;          //Not used in this design.
	 wire sigout1;          //Not used in this design.
	 wire sigout2;          //Not used in this design.
	 wire sigout3;          //Not used in this design.
	 wire read;             //Read strobe.
	 wire write;            //Write strobe.
	 wire [15:0]id;         //ID for peripheral devices.
	 wire [15:0]outdata;    //Data for peripheral devices.
	 wire [35:0]inst;       //Instruction from program ROM.
	 wire [15:0]in_port;    //Input from data MUX.
	 wire [15:0]address;    //Address truncated by bus converter.
	 
	 //I2C controller.
	 wire [15:0]i2cstatus;
	 wire [7:0]i2cdata;
	 
	 //UART
	 wire [7:0]uartdata;
	 wire [11:0]txcount;
	 wire [11:0]rxcount;
	 
	 //Cellular RAM controller.
	 wire busy;
	 wire [9:0]readBufAddr;
	 wire [15:0]readBufData;
	 wire VGAClk;
	 
	 //VGA controller.
	 wire frameInterrupt;
	 wire dataInterrupt;
	 
	 //Camera controller.
	 wire [10:0]camAddress;
	 wire camDataInt;
	 wire camFrameInt;
	 
	 /*********************************************************************************************/
	 
	 wire clk23MHz;
    wire clk0;
	 
	 DCM_SP #( 
        .CLKFX_DIVIDE(13),
        .CLKFX_MULTIPLY(12),      
        .CLKIN_PERIOD(39.721946)
    ) DCM0 (
        .CLK0(clk0),
        .CLKFX(clk23MHz),
        .CLKFB(clk0),
        .CLKIN(clk25MHz),
        .RST(1'b0)
    );	 
	 
	 assign xclk = clk23MHz;
	 
	 /*********************************************************************************************/
	 
	 or or1(vgaorout, ack0, ack2);
	 
	 //Flip-flop for interrupt 0.
	 FF ff0(.set(dataInterrupt), .reset(vgaorout), .sigout(sigout0));
	 
	 //Flip-flop for interrupt 1.
	 FF ff1(.set(camDataInt), .reset(ack1), .sigout(sigout1));
	 
	 //Flip-flop for interrupt 2.
	 FF ff2(.set(frameInterrupt), .reset(ack2), .sigout(sigout2));
	 
	 //Flip-flop for interrupt 3.
	 FF ff3(.set(camFrameInt), .reset(ack3), .sigout(sigout3));
	 
	 //Processor input data MUX.
	 dataMUX datamux(.read(read), .id(id), .i2cdata({8'h00, i2cdata}), .i2cstatus(i2cstatus), .dout(in_port), 
	                 .uartdata({8'h00, uartdata}), .txcount({4'h0, txcount}), .rxcount({4'h0, rxcount}),
						  .busy({15'h0000, busy}), .sync({15'h0000, camvert})); 
	 
	 //Program ROM for NMPSM3.
	 prgROM ROM(.clka(clk), .addra(address[8:0]), .douta(inst));	  
	 
	 //NMPSM3 soft processor.	 
	 NMPSM3 nmpsm3(.clk(clk), .reset(btn), .IRQ0(sigout0), .IRQ1(sigout1), .IRQ2(sigout2), .IRQ3(sigout3),
	               .INSTRUCTION(inst), .IN_PORT(in_port), .READ_STROBE(read), .WRITE_STROBE(write), .IRQ_ACK0(ack0),
						.IRQ_ACK1(ack1), .IRQ_ACK2(ack2), .IRQ_ACK3(ack3), .ADDRESS(address), .OUT_PORT(outdata), 
						.PORT_ID(id));
	
	 //Cellular RAM controller.
	 CellRAMBurstController RAMcont(.busy(busy), .clk(clk), .write(write), .data(outdata), .id(id), 
	                                .writeBufAddr(camAddress),
											  .writeBufData(camdata),
											  .writeBufClk(pclk),
											  .writeBufWE(camhorz),
											  .readBufAddr(readBufAddr), .readBufData(readBufData),
											  .readBufClk(VGAClk), .LB(LB), .UB(UB), .OE(OE), .WE(WE), .ADV(ADV), .CE(CE),
											  .CRE(CRE), .RAM_CLK(RAM_CLK), .O_WAIT(O_WAIT), .A(A), .DQ(DQ));
											  
	 //VGA controller.
	 VGA vga_cont(.clk25MHz(clk25MHz), .VGAData(readBufData), .VGAAddress(readBufAddr), .VGAClk(VGAClk), .vga(vga),
	              .hsync(hsync), .vsync(vsync), .frameInterrupt(frameInterrupt), .dataInterrupt(dataInterrupt));
	
     //I2C controller.
	 I2CTest1 i2c(.SCL(camscl), .SDA(camsda), .reset(btn), .write(write), .clk(clk), .id(id), .din(outdata),
	              .i2cdata(i2cdata), .i2cstatus(i2cstatus));
	 
	 //UART
	 uart u(.clk(clk), .reset(btn), .id(id), .din(outdata), .write(write), .rx(rx),
           .tx(tx), .dout(uartdata), .txcount(txcount), .rxcount(rxcount));
	
	 //Camera controller.
	 cam_Controller camCont(.pclk(pclk), .vsync(camvert), .href(camhorz), .address(camAddress),
	                        .dataInterrupt(camDataInt), .frameInterrupt(camFrameInt));

endmodule
