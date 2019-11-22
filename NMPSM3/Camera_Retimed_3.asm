.size 512

;----------------------------------------------------------------------------------------;
;----------------------------------------Defines-----------------------------------------;
;----------------------------------------------------------------------------------------;

;**************************************Output Ports**************************************;
.alias SET_BAUD             #$0200              ;
.alias TX_STORE_BYTE        #$0201              ;
.alias TX_FLUSH             #$0202              ;UART control.
.alias TX_PURGE             #$0203              ;
.alias RX_NEXT_BYTE         #$0204              ;
.alias RX_PURGE             #$0205              ;

.alias LOAD_CLOCK_RATE      #$8000              ;
.alias LOAD_MASTER_TX_DATA  #$8001              ;
.alias LOAD_MASTER_TYPE     #$8002              ;I2C control.
.alias MASTER_ENABLED       #$8003              ;
.alias MASTER_TX_VALID      #$8004              ;
.alias RX_VALID             #$8005              ;

.alias BURST_WRITE          #$0050              ;
.alias BURST_READ           #$0051              ;
.alias WRITE_LENGTH         #$0052              ;
.alias READ_LENGTH          #$0053              ;
.alias WRITE_ADDR_H         #$0054              ;Cell RAM control.
.alias WRITE_ADDR_L         #$0055              ;
.alias READ_ADDR_H          #$0056              ;
.alias READ_ADDR_L          #$0057              ;
.alias SET_WB_ADDR          #$0058              ;
.alias SET_RB_ADDR          #$0059              ;

.alias WRITE_BUF_ADDR       #$0031              ;External RAM control.
.alias WRITE_BUF_DATA       #$0032              ;

;**************************************Input Ports***************************************;
.alias I2C_DATA             #$0001              ;I2C status.
.alias I2C_STATUS           #$0002              ;

.alias UART_DATA            #$0003              ;
.alias TX_COUNT             #$0004              ;UART status.
.alias RX_COUNT             #$0005              ;

.alias CAMVERT              #$0006              ;Camera vertical refresh.

.alias BUSY                 #$0008              ;Cell RAM busy status.

.alias SYNC                 #$0009              ;Vsync signals for VGA and camera.

;***********************************Processor Registers**********************************;
.alias temp_reg0            $0000               ;Used for misc. processing.

.alias i2c_tx_data          $0001               ;
.alias i2c_type             $0002               ;I2C value registers.
.alias i2c_status_in        $0003               ;
.alias i2c_read_byte        $0004               ;

.alias uart_tx_byte         $0005               ;
.alias uart_rx_byte         $0006               ;UART value registers.
.alias uart_tx_count        $0007               ;
.alias uart_rx_count        $0008               ;

.alias wait_value_lo        $0009               ;Delay registers.
.alias wait_value_hi        $000A               ;

.alias i2c_user_add         $000B               ;User entered I2C address.
.alias i2c_user_val         $000C               ;User entered I2C data.
.alias i2c_user_read        $000D               ;User requested I2C data byte.

.alias comp_reg             $000E               ;Compare register.
.alias is_valid_hex         $000F               ;set if valid hex number found, cleared if invalid.
.alias convert_reg          $0010               ;Stores ASCII converted to binary.

.alias buf_cur_pointer      $0011               ;Pointer to current position in uart buffer.
.alias buf_end_pointer      $0012               ;Pointer to last position in uart buffer.               
.alias uart_buf             $0013               ;thru $003F

.alias read_addr_l          $0014               ;Cell RAM read address, low byte.
.alias read_addr_h          $0015               ;Cell RAM read address, high byte.

.alias write_addr_l         $0016               ;Cell RAM write address, low byte.
.alias write_addr_h         $0017               ;Cell RAM write address, high byte.

.alias wh_f_start           $0020               ;Indicate start of white at beginning of frame.
.alias wh_f_end             $0021               ;Indicate end of white at beginning of frame.

.alias gr_f_start           $0022               ;Indicate start of green at beginning of frame.
.alias gr_f_end             $0023               ;Indicate end of green at beginning of frame.

.alias wh_r_start           $0024               ;Indicate start of white at beginning of row.
.alias wh_r_end             $0025               ;Indicate end of white at beginning of row.

.alias gr_r_start           $0026               ;Indicate start of green at beginning of row.
.alias gr_r_end             $0027               ;Indicate end of green at beginning of row.

.alias this_color           $0028               ;Holds current color.

.alias row_begin            $0029               ;1 = start at row, 0 = middle of row.

.alias loop_counter         $002A               ;Used for reloading buffer for new frame.

.alias int_reg0             $002B               ;General purpose register used in interrupts.

;****************************************Constants***************************************;
;True/false defines.
.alias FALSE                #$0000
.alias TRUE                 #$0001

.alias STRING_BUF_START     #$0030              ;Start address of string buffer.
.alias STRING_BUF_END       #$003F              ;End address of string buffer.

;I2C types.
.alias MASTER_P             #$0000              ;Stop
.alias MASTER_S             #$0001              ;Start
.alias MASTER_TX_C          #$0002              ;Continue, next byte will be transmitted.
.alias MASTER_RX_C          #$0003              ;Continue, next byte will be received.

.alias SOURCE_WRITE         #$0042              ;Camera read and write addresses.
.alias SOURCE_READ          #$0043              ;

;ASCII numbers.
.alias ZERO                 #$30
.alias ONE                  #$31
.alias TWO                  #$32
.alias THREE                #$33
.alias FOUR                 #$34
.alias FIVE                 #$35
.alias SIX                  #$36
.alias SEVEN                #$37
.alias EIGHT                #$38
.alias NINE                 #$39

;ASCII letters.
.alias A                    #$41
.alias B                    #$42
.alias C                    #$43
.alias D                    #$44
.alias E                    #$45
.alias F                    #$46
.alias G                    #$47
.alias H                    #$48
.alias I                    #$49
.alias J                    #$4A
.alias K                    #$4B
.alias L                    #$4C
.alias M                    #$4D
.alias N                    #$4E
.alias O                    #$4F
.alias P                    #$50
.alias Q                    #$51
.alias R                    #$52
.alias S                    #$53
.alias T                    #$54
.alias U                    #$55
.alias V                    #$56
.alias W                    #$57
.alias X                    #$58
.alias Y                    #$59
.alias Z                    #$5A

.alias a                    #$61
.alias b                    #$62
.alias c                    #$63
.alias d                    #$64
.alias e                    #$65
.alias f                    #$66
.alias g                    #$67
.alias h                    #$68
.alias i                    #$69
.alias j                    #$6A
.alias k                    #$6B
.alias l                    #$6C
.alias m                    #$6D
.alias n                    #$6E
.alias o                    #$6F
.alias p                    #$70
.alias q                    #$71
.alias r                    #$72
.alias s                    #$73
.alias t                    #$74
.alias u                    #$75
.alias v                    #$76
.alias w                    #$77
.alias x                    #$78
.alias y                    #$79
.alias z                    #$7A

;ASCII symbols.
.alias SPACE                #$20
.alias COLON                #$3A
.alias COMMA                #$2C
.alias PERIOD               #$2E
.alias CR                   #$0D                ;Carriage return.
.alias FSLASH               #$2F                ;Forward slash.
.alias LBAR                 #$5F                ;Underscore.
.alias MBAR                 #$2D                ;Minus sign.
.alias UBAR                 #$FF                ;Upper bar.
.alias STAR                 #$2A                ;Multiply sign.
.alias OPEN_C_BRACE         #$7B                ;Open curly brace.

;****************************************Bitmasks****************************************;
.alias I2C_MASTER_TX_VALID  #%0000000000000001  ;I2C controller
.alias I2C_MASTER_INACTIVE  #%0000000000000010  ;status bits.
.alias I2C_MASTER_RX_VALID  #%0000000000000100  ;

;----------------------------------------------------------------------------------------;
;-------------------------------------Start Of Code--------------------------------------;
;----------------------------------------------------------------------------------------;

jump Reset                                      ;
jump Interrupt0                                 ;
jump Interrupt1                                 ;Reset and interrupt vectors.
jump Interrupt2                                 ;
jump Interrupt3                                 ;

Interrupt0:
    call BusyLoop                               ;Wait for other RAM accesses to finish.

    load int_reg0 read_addr_l                   ;set lower address of cell RAM read.
    out  int_reg0 READ_ADDR_L                   ;

    load int_reg0 read_addr_h                   ;set upper address of cell RAM read.
    out  int_reg0 READ_ADDR_H                   ;

    load int_reg0 #320                          ;Prepare to transfer 320 words from-->
    out  int_reg0 READ_LENGTH                   ;cell RAM to read buffer.   

    load int_reg0 #0                            ;Initiate burst read.
    out  int_reg0 BURST_READ                    ;

    add  read_addr_l #320                       ;Move to next cell RAM read address block. 
    addc read_addr_h #0                         ;

    rtie

Interrupt1:
    call BusyLoop                               ;Wait for other RAM accesses to finish.

    load int_reg0 write_addr_l                  ;set lower address of cell RAM write.
    out  int_reg0 WRITE_ADDR_L                  ;

    load int_reg0 write_addr_h                  ;set upper address of cell RAM write.
    out  int_reg0 WRITE_ADDR_H                  ;

    load int_reg0 #320                          ;Prepare to transfer 320 words from-->
    out  int_reg0 WRITE_LENGTH                  ;write buffer to cell RAM.   

    load int_reg0 #0                            ;Initiate burst write.
    out  int_reg0 BURST_WRITE                   ;

    add  write_addr_l #320                      ;Move to next cell RAM write address block. 
    addc write_addr_h #0                        ;

    comp write_addr_l #$B000                    ;Is lower pointer at end of buffer?
    jpnz FinishInt1                             ;

    comp write_addr_h #$0004                    ;Is upper pointer at end of buffer?
    jpnz FinishInt1                             ;

    load write_addr_l #0                        ;Reset cell RAM write address.
    load write_addr_h #0                        ;

    FinishInt1:
    rtie

Interrupt2:
    load read_addr_l #0                         ;Reset cell RAM read address.
    load read_addr_h #0                         ;

    call CheckSync                              ;Sync frame if necessary (for reset).

    ein0                                        ;Enable VGA data interrupt.
    rtie

CheckSync:
    in   int_reg0 SYNC                          ;
    comp int_reg0 #1                            ;Check if cam vsync and VGA vsync are aligned.
    rtnz                                        ;

    load write_addr_l #0                        ;Reset cell RAM write address.
    load write_addr_h #0                        ;

    load int_reg0 #0                            ;
    out  int_reg0 SET_WB_ADDR                   ;Reset read/write buffer pointers.
    out  int_reg0 SET_RB_ADDR                   ;
    ret

BusyLoop:
    in   int_reg0 BUSY                          ;
    comp int_reg0 #0                            ;Is RAM controller busy?
    jpnz BusyLoop                               ;if so, loop until it is idle.
    ret     

Interrupt3:
    rtie

ClearRegs:                                      ;
    load 0 #$3FF                                ;
    load 1 #0                                   ;
    ClearRegsLoop:                              ;Clear all internal
    stor 1 (0)                                  ;processor registers.
    sub  0 #1                                   ;
    jpnz ClearRegsLoop                          ;
    ret

Reset: 
    call ClearRegs                              ;Zero all hardware regs.

    load i2c_tx_data #$3F                       ;Set i2c clock to 400KHz.
    out  i2c_tx_data LOAD_CLOCK_RATE            ;

    load uart_tx_byte #$D9                      ;Set UART baud rate to 115200.
    out  uart_tx_byte SET_BAUD                  ;

    call InitCamera                             ;Initialize camera module.
    
    ein2                                        ;Enable frame interrupts. 
    ein1                                        ;

MainLoop:
    call CheckUART                              ;Check for waiting data in UART. 
    jump MainLoop

;Wait for the I2C line to go idle.
Wait_For_Stop:
    in   i2c_status_in I2C_STATUS               ;
    and  i2c_status_in I2C_MASTER_INACTIVE      ;Wait for I2C controller
    comp i2c_status_in I2C_MASTER_INACTIVE      ;to be inactive.
    jpnz Wait_For_Stop                          ;
    ret                                         ;

;This function transmits a byte of information out the I2C line.
I2CTXByte:
    in   i2c_status_in I2C_STATUS               ;
    and  i2c_status_in I2C_MASTER_TX_VALID      ;Check I2C valid status.
    comp i2c_status_in #1                       ;

    jpnz  I2CTXByte                             ;Loop until buffer is empty.

    out  i2c_type LOAD_MASTER_TYPE              ;Load byte type.
    out  i2c_tx_data LOAD_MASTER_TX_DATA        ;Load TX buffer data.
    load temp_reg0 #1                           ;
    out  temp_reg0 MASTER_TX_VALID              ;Validate byte to send.
    out  temp_reg0 MASTER_ENABLED               ;Start I2C tx(if not already started).
    ret                                         ;

;This function receives a byte of information from the I2C line.
I2CRXByte:
    in   i2c_status_in I2C_STATUS               ;
    and  i2c_status_in I2C_MASTER_RX_VALID      ;Check I2C valid status.
    comp i2c_status_in #4                       ;

    jpnz  I2CRXByte                             ;Loop until rx buffer is valid.

    in   i2c_read_byte I2C_DATA                 ;Read in received byte.
    load temp_reg0 #0                           ;
    out  temp_reg0 RX_VALID                     ;Rx byte has been read.
    ret                                         ;

InitCamera:
    ;----------------------Horizontal Setup------------------------------
    load i2c_tx_data SOURCE_WRITE               ;
    load i2c_type MASTER_TX_C                   ;Camera write.
    call I2CTXByte                              ;

    load i2c_tx_data #$0C                       ;
    load i2c_type MASTER_TX_C                   ;Register address.
    call I2CTXByte                              ;

    load i2c_tx_data #$50                       ;
    load i2c_type MASTER_P                      ;Horizontal mirror.
    call I2CTXByte                              ;

    call Wait_For_Stop
    
    ;----------------------Vertical Setup--------------------------------

    ;----------------------Output Setup----------------------------------
    load i2c_tx_data SOURCE_WRITE               ;
    load i2c_type MASTER_TX_C                   ;Camera write.
    call I2CTXByte                              ;

    load i2c_tx_data #$12                       ;
    load i2c_type MASTER_TX_C                   ;Register address.
    call I2CTXByte                              ;

    load i2c_tx_data #$06                       ;
    load i2c_type MASTER_P                      ;RGB565 output format.
    call I2CTXByte                              ;

    call Wait_For_Stop
    ret

CheckUART:
    in   uart_rx_count RX_COUNT                 ;Are bytes waiting in rx buffer?
    comp uart_rx_count #0                       ;
    rtz                                         ;If not, exit.

    in   uart_rx_byte UART_DATA                 ;Get UART byte.
    out  uart_rx_byte RX_NEXT_BYTE              ;Move to next position.

    call PutBufferByte                          ;Store byte in string buffer.
    call EchoByte                               ;Echo byte back to terminal.
    call CheckStringEnd                         ;Check for end of string.
    ret

;Wait for the UART transmit buffer to empty.
WaitForUART:
    in   uart_tx_count TX_COUNT                 ;Check to see how many bytes
    comp uart_tx_count #0                       ;are in the UART buffer.
    jpnz WaitForUART                            ;If none, done waiting.
    ret

InitStringBuffer:
    load buf_end_pointer STRING_BUF_START       ;Initialize string buffer pointers.
    load buf_cur_pointer STRING_BUF_START       ;
    ret

PutBufferByte:
    stor uart_rx_byte (buf_end_pointer)         ;Put UART byte in buffer.
    add  buf_end_pointer #1                     ;
    ret

EchoByte:
    out  uart_rx_byte TX_STORE_BYTE             ;Echo byte back to terminal.
    out  temp_reg0 TX_FLUSH                     ;
    ret

EchoError:
    load wait_value_lo #$00                     ;Wait for any multi-character input to-->
    load wait_value_hi #$01                     ;fill the buffer.
    call WaitForDelay                           ;
    out  temp_reg0 RX_PURGE                     ;then get rid of any garbage in the UART.

    load temp_reg0 #0                           ;
    out  temp_reg0 TX_STORE_BYTE                ;
    load temp_reg0 E                            ;
    out  temp_reg0 TX_STORE_BYTE                ;
    load temp_reg0 R                            ;
    out  temp_reg0 TX_STORE_BYTE                ;
    load temp_reg0 R                            ;Send error message to terminal.
    out  temp_reg0 TX_STORE_BYTE                ;
    load temp_reg0 CR                           ;
    out  temp_reg0 TX_STORE_BYTE                ;
    out  temp_reg0 TX_FLUSH                     ;
    
    call WaitForUART                            ;Wait for error message to finish flushing. 
    call InitStringBuffer                       ;Reinitialize string buffer.
    ret

EchoOK:
    load temp_reg0 O                            ;
    out  temp_reg0 TX_STORE_BYTE                ;
    load temp_reg0 K                            ;
    out  temp_reg0 TX_STORE_BYTE                ;Send ok message to terminal.   
    load temp_reg0 CR                           ;
    out  temp_reg0 TX_STORE_BYTE                ;
    out  temp_reg0 TX_FLUSH                     ;
    
    call InitStringBuffer                       ;Reinitialize string buffer.
    ret

CheckStringEnd:
    comp buf_end_pointer STRING_BUF_START       ;Exit if empty string.
    rtz                                         ;

    comp buf_end_pointer STRING_BUF_END         ;Buffer overflow. Error.
    jpz  EchoError                              ;
    
    load buf_cur_pointer buf_end_pointer        ;Point to last valid byte.
    sub  buf_cur_pointer #1                     ;

    load temp_reg0 (buf_cur_pointer)            ;Has carriage return been sent? if so-->
    comp temp_reg0 CR                           ;jump to validate string.
    jpz  CheckStringFormat                      ;
    ret

CheckStringFormat:
    load buf_cur_pointer STRING_BUF_START       ;Point to beginning of string buffer.

    load temp_reg0 w                            ;
    load comp_reg (buf_cur_pointer)             ;Is this a write operation? If so, jump.
    comp temp_reg0 comp_reg                     ;
    jpz WriteVerify                             ;

    load temp_reg0 r                            ;
    load comp_reg (buf_cur_pointer)             ;Is this a read operation? If so, jump.
    comp temp_reg0 comp_reg                     ;
    jpz ReadVerify                              ;

    jump EchoError                              ;Error. Unrecognized command.

VerifyHex:
    load temp_reg0 (buf_cur_pointer)            ;Get current hex value to check.

    comp temp_reg0 ZERO                         ;If less than numbers, it is invalid.
    jpc InvalidHex                              ;

    comp temp_reg0 COLON                        ;If a number, it is valid.
    jpc ValidHex                                ;

    comp temp_reg0 a                            ;If less than lower case letters, it is invalid.
    jpc InvalidHex                              ;

    comp temp_reg0 g                            ;If less than g, it is invalid.
    jpc ValidHex                                ;

    jump InvalidHex                             ;Else it is invalid.

    ValidHex:
    load is_valid_hex TRUE                      ;Indicate the hex value is valid.
    ret

    InvalidHex:
    load is_valid_hex FALSE                     ;Indicate the hex value is invalid.
    ret

ConvertToBinary:
    load convert_reg (buf_cur_pointer)          ;Get upper byte of acii character.
    sub  convert_reg ZERO                       ;
    comp convert_reg #$0A                       ;Convert to number.
    jpc  DoUpperConvert                         ;Jump if 0 thru 9.
    sub  convert_reg #$27                       ;Convert to letter.
    
    DoUpperConvert:
    asl  convert_reg                            ;
    asl  convert_reg                            ;Shift to upper nibble.
    asl  convert_reg                            ;
    asl  convert_reg                            ;

    stor convert_reg temp_reg0                  ;Save result and move to next character.
    add  buf_cur_pointer #1                     ;

    load convert_reg (buf_cur_pointer)          ;Get lower byte of ascii character.
    sub  convert_reg ZERO                       ;
    comp convert_reg #$0A                       ;Convert to number.
    jpc  DoConvert                              ;Jump if 0 thru 9.
    sub  convert_reg #$27                       ;Convert to letter.

    DoConvert:
    and  convert_reg #$0F                       ;Combine upper and lower nibbles.
    or   convert_reg temp_reg0                  ;
    ret

ToASCIIAndSend:
    load temp_reg0 uart_tx_byte                 ;Get byte to convert and transmit.
    lsr  temp_reg0                              ;
    lsr  temp_reg0                              ;Move upper nibble to lower nibble.
    lsr  temp_reg0                              ;
    lsr  temp_reg0                              ;
    add  temp_reg0 #$30                         ;Convert to ASCII.

    comp temp_reg0 #$3A                         ;Check if needs to be converted to
    jpc  UpperNibbleOut                         ;letter (A through F).

    add  temp_reg0 #$27                         ;Convert to letter.

    UpperNibbleOut:
    out  temp_reg0 TX_STORE_BYTE                ;Transmit upper nibble.

    load temp_reg0 uart_tx_byte                 ;Keep only lower nibble.
    and  temp_reg0 #$F                          ;
    add  temp_reg0 #$30                         ;Convert to ASCII.

    comp temp_reg0 #$3A                         ;Check if needs to be converted to
    jpc  LowerNibbleOut                         ;letter (A through F).

    add  temp_reg0 #$27                         ;Convert to letter.

    LowerNibbleOut:
    out  temp_reg0 TX_STORE_BYTE                ;Transmit lower nibble.

    load temp_reg0 CR                           ;Transmit a carriage return.
    out  temp_reg0 TX_STORE_BYTE                ;

    out  temp_reg0 TX_FLUSH                     ;Flush transmit buffer.
    ret

ReadVerify:
    load temp_reg0 SPACE                        ;Check for proper spacing.

    add  buf_cur_pointer #1                     ;
    load comp_reg (buf_cur_pointer)             ;Space between operation and first number.
    comp temp_reg0 comp_reg                     ;
    jpnz EchoError                              ;

    load temp_reg0 CR                           ;Check for carriage return.

    add  buf_cur_pointer #3                     ;
    load comp_reg (buf_cur_pointer)             ;Carriage return at end of line.
    comp temp_reg0 comp_reg                     ;
    jpnz EchoError                              ;

    sub  buf_cur_pointer #2                     ;Point to number, high byte.
    call VerifyHex                              ;Make sure it is valid.

    comp is_valid_hex FALSE                     ;Is hex value valid?-->
    jpz  EchoError                              ;If not, branch.

    add  buf_cur_pointer #1                     ;Point to first number, low byte.
    call VerifyHex                              ;Make sure it is valid.

    comp is_valid_hex FALSE                     ;Is hex value valid?-->
    jpz  EchoError                              ;If not, branch.
    
    sub  buf_cur_pointer #1                     ;
    call ConvertToBinary                        ;Convert read address to binary and store it.
    stor convert_reg i2c_user_add               ;
    
    load i2c_tx_data SOURCE_WRITE               ;
    load i2c_type MASTER_TX_C                   ;Camera write.
    call I2CTXByte                              ;

    load i2c_tx_data i2c_user_add               ;
    load i2c_type MASTER_P                      ;Register address.
    call I2CTXByte                              ;

    call Wait_For_Stop

    load i2c_tx_data SOURCE_READ                ;
    load i2c_type MASTER_RX_C                   ;Read byte from I2C register.
    call I2CTXByte                              ;
    call I2CRXByte                              ;

    load i2c_type MASTER_P                      ;End read.
    call I2CTXByte                              ;

    call Wait_For_Stop

    stor i2c_read_byte i2c_user_read            ;Save byte from I2C line.
    load  uart_tx_byte i2c_user_read            ;Transmit byte out UART.
    call ToASCIIAndSend                         ;

    call InitStringBuffer                       ;Reinitialize string buffer.

    ret

WriteVerify:
    load temp_reg0 SPACE                        ;Check for proper spacing.

    add buf_cur_pointer #1                      ;
    load comp_reg (buf_cur_pointer)             ;Space between operation and first number.
    comp temp_reg0 comp_reg                     ;
    jpnz EchoError                              ;

    add  buf_cur_pointer #3                     ;
    load comp_reg (buf_cur_pointer)             ;Space between first number and second number.
    comp temp_reg0 comp_reg                     ;
    jpnz EchoError                              ;

    load temp_reg0 CR                           ;Check for carriage return.

    add  buf_cur_pointer #3                     ;
    load comp_reg (buf_cur_pointer)             ;Carriage return at end of line.
    comp temp_reg0 comp_reg                     ;
    jpnz EchoError                              ;

    sub  buf_cur_pointer #5                     ;Point to first number, high byte.
    call VerifyHex                              ;Make sure it is valid.

    comp is_valid_hex FALSE                     ;Is hex value valid?-->
    jpz  EchoError                              ;If not, branch.

    add buf_cur_pointer #1                      ;Point to first number, low byte.
    call VerifyHex                              ;Make sure it is valid.

    comp is_valid_hex FALSE                     ;Is hex value valid?-->
    jpz  EchoError                              ;If not, branch.

    add  buf_cur_pointer #2                     ;Point to second number, high byte.
    call VerifyHex                              ;Make sure it is valid.

    comp is_valid_hex FALSE                     ;Is hex value valid?-->
    jpz  EchoError                              ;If not, branch.

    add  buf_cur_pointer #1                     ;Point to second number, low byte.
    call VerifyHex                              ;Make sure it is valid.

    comp is_valid_hex FALSE                     ;Is hex value valid?-->
    jpz  EchoError                              ;If not, branch.

    sub  buf_cur_pointer #4                     ;
    call ConvertToBinary                        ;Convert first number to binary and store.
    stor convert_reg i2c_user_add               ;

    add  buf_cur_pointer #2                     ;
    call ConvertToBinary                        ;Convert second number to binary and store.
    stor convert_reg i2c_user_val               ;
    
    load i2c_tx_data SOURCE_WRITE               ;
    load i2c_type MASTER_TX_C                   ;Camera write.
    call I2CTXByte                              ;

    load i2c_tx_data i2c_user_add               ;
    load i2c_type MASTER_TX_C                   ;Register address.
    call I2CTXByte                              ;

    load i2c_tx_data i2c_user_val               ;
    load i2c_type MASTER_P                      ;Register value.
    call I2CTXByte                              ;

    call Wait_For_Stop

    call EchoOK                                 ;Indicate successful write.
    ret

;This function consumes processor cycles for a defined period of time.
WaitForDelay:
    comp wait_value_hi #0                       ;
    jpnz DecWaitRegs                            ;Check for delay value of zero.
    comp wait_value_lo #0                       ;
    rtz                                         ;Is delay zero? if so, exit.

    DecWaitRegs:
    clrc                                        ;
    subc wait_value_lo #1                       ;Decrement wait registers.
    subc wait_value_hi #0                       ;  
    jump WaitForDelay                           ;
    

