; Implantable Inertial Sensor (IIS) Program Version 2.4
; -----------------------------------------------------

; This code runs in the OSR8 microprocessor of the A3035A. It reads out
; the accelerometer at 128 SPS per axis. If we enable the gyroscope, it
; turns on the gyroscope and reads it out at 128 SPS as well. Each sensor 
; produces three channels of telemetry data, each sample is an unsigned 
; sixteen-bit integer. The coordinates of the sensors are re-arranged so 
; that their directions are aligned.

; Configuration constants
const gyr_en         0x00 ; Turn on and transmit gyroscope measurements.

; Calibration Constants
const tx_frequency      4 ; Transmit frequency calibration
const device_id         4 ; Will be used as the first channel number.
const sample_period     0 ; Sample period in units of RCK periods, use 0 for 256.

; Address Map Boundary Constants
const mmu_vmem 0x0000 ; Base of Variable Memory
const mmu_ctrl 0x0600 ; Base of Control Space
const mmu_sba  0x0300 ; Stack Base Address

; Address Map Constants
const mmu_shb  0x0600 ; Sensor Data HI Byte 
const mmu_slb  0x0601 ; Sensor Data LO Byte
const mmu_sar  0x0602 ; Sensor Address Register
const mmu_scr  0x0604 ; Sensor Control Register
const mmu_irqb 0x0610 ; Interrupt Request Bits
const mmu_imsk 0x0612 ; Interrupt Mask Bits
const mmu_irst 0x0614 ; Interrupt Reset Bits
const mmu_iset 0x0616 ; Interrupt Set Bits
const mmu_itp  0x0618 ; Interrupt Timer Period 
const mmu_rst  0x0619 ; System Reset
const mmu_sph  0x061B ; Initial Stack Pointer HI Byte
const mmu_spl  0x061C ; Initial Stack Pointer LO Byte
const mmu_xhb  0x0620 ; Transmit HI Byte
const mmu_xlb  0x0621 ; Transmit LO Byte
const mmu_xcn  0x0622 ; Transmit Channel Number
const mmu_xcr  0x0624 ; Transmit Control Register
const mmu_xfc  0x0626 ; Transmit Frequency Calibration
const mmu_etc  0x0630 ; Enable Transmit Clock
const mmu_tcf  0x0632 ; Transmit Clock Frequency
const mmu_tcd  0x0634 ; Transmit Clock Divider
const mmu_bcc  0x0636 ; Boost CPU Clock
const mmu_tpr  0x0638 ; Test Point Register
const mmu_mia  0x063A ; Multiplier Input A
const mmu_mib  0x063B ; Multiplier Input B
const mmu_moh  0x063C ; Multiplier Output HI	
const mmu_mol  0x063D ; Multiplier Output LO

; Sensor Control Constants
const gy_rd16    0x05 ; Read Sixteen-Bit Word from Gyroscope
const gy_wr16    0x07 ; Write Sixteen-Bit Word to Gyroscope
const gy_rd8     0x01 ; Read Eight-Bit Byte from Gyroscope
const gy_wr8     0x03 ; Write Eight-Bit Byte to Gyroscope
const acc_rd16   0x04 ; Read Sixteen-Bit Word from Accelerometer
const acc_wr16   0x06 ; Write Sixteen-Bit Word to Accelerometer
const acc_rd8    0x00 ; Read Eight-Bit Byte from Accelerometer
const acc_wr8    0x02 ; Write Eight-Bit Byte to Accelerometer

; Sensor Registers Locations
const gyr_sens_tmr_0      0x17
const gyr_sens_tmr_1      0x18
const gyr_sens_tmr_2      0x19
const acc_sens_tmr_1	  0x19
const sens_tmp_lo		  0x20
const sens_tmp_hi		  0x21
const gyr_z				  0x16
const gyr_x 			  0x12
const gyr_y				  0x14
const acc_x				  0x12
const acc_y  			  0x14
const acc_z 			  0x16
const gyr_cmd		      0x7E
const gyr_rng 			  0x43
const acc_pwr_ctrl        0x7D ; PWR_CTRL register address.
const acc_rng             0x41
const acc_pwr_conf        0x7C ; PWR_CONF register address.
const acc_features_in     0x5E
const acc_init_ctrl       0x59 
const acc_internal_status 0x2A
const acc_conf            0x40 ; ACC_CONF register address.

; Configuration Constants
const tk_divisor    	12     ; Number of ring periods per 100 ns.
const acc_init_cntr 	0x0C00 ; Value for HL to count down from.
const min_tcf       	75     ; Minimum TCK periods per half RCK period.
const gyr_normal		0x15   ; Normal operation code.
const gyr_susp          0x14   ; Suspend operation code.
const gyr_rng_hi 		0x00   ; Code for largest range data value for gyr
const gyr_rng_lo		0x03   ; Code for smallest range data value for gyr
const gyr_rng_mid		0x01   ; Code for mid range data value for gyr
const acc_rng_hi 		0x03   ; Code for mid range data value for acc
const acc_25hz          0x06   ; Output data rate 100 Hz, no averaging, no filter
const acc_100hz         0x08   ; Output data rate 100 Hz, no averaging, no filter
const acc_daq			0x04   ; Enable accelerometer data acquisition.
const acc_pwr_sv		0x03   ; Advanced power save and fifo self-start.

; Timing consstants.
const tx_delay      50  ; Wait time for sample transmission, TCK periods.
const sa_delay      70  ; Wait time for sensor access, TCK periods.
const initial_tcd   15  ; Max possible value of the transmit clock divisor.
const acc_startup   50  ; Accelerometer start-up delay in RCK cycles.
const boot_delay    10  ; Boot delay in multiples of 7.8 ms.

; Math constants.
const off_16bs    0x80  ; Convert sixteen bit signed to unsigned.

; ------------------------------------------------------------

; The CPU reserves two locations 0x0000 for the start of program
; execution, and 0x0003 for interrupt execution. We put jumps at
; both locations. A jump takes exactly three bytes.
start: 
jp initialize
jp interrupt

; ------------------------------------------------------------
; Configure the accelerometer. We do not perform the initialization
; suggested by the BMA423 data sheet, where we write six kilobytes
; of configuration data to the device. Instead, we write to the power
; configuration register, then the power control register, then wait
; for a time greater than 500 us, then set the update rate and 
; measurement range. Beware changing the order of the first two 
; writes and the delay. The accelerometer can deliver zeros if we
; deviate from the correct sequence.

acc_config:
push F
push A  

ld A,acc_pwr_conf  ; Load A with power configuration register address.
ld (mmu_sar),A     ; Write A to sensor address register.
ld A,acc_pwr_sv    ; Load A with power configuration code.
ld (mmu_slb),A     ; Write A to sensor low byte.
ld A,acc_wr8	   ; Load A with eight-bit write command.
ld (mmu_scr),A     ; Write A to sensor control register.

ld A,acc_pwr_ctrl  ; Load A with power control register address.
ld (mmu_sar),A 	   ; Write A to sensor address register.
ld A,acc_daq       ; Load A with power control code.
ld (mmu_slb),A     ; Write A to sensor low byte.
ld A,acc_wr8	   ; Load A with eight-bit write command.
ld (mmu_scr),A 	   ; Write A to sensor control register.

ld A,acc_startup   ; Load A with accelerometer start-up delay.
dly A              ; Wait for accelerometer to complete startup.

ld A,acc_conf      ; Load A with configuration register address.
ld (mmu_sar),A     ; Write A to sensor address register.
ld A,acc_100hz     ; Load A with chosen configuration code.
ld (mmu_slb),A     ; Write A to sensor low byte.
ld A,acc_wr8       ; Load A with eight-bit write command.
ld (mmu_scr),A     ; Write A to sensor control register.

ld A,acc_rng	   ; Load A with range register address.
ld (mmu_sar),A 	   ; Write A to sensor address register.
ld A,acc_rng_hi    ; Load A with acceleromter range code.
ld (mmu_slb),A 	   ; Write A to sensor low byte.
ld A,acc_wr8       ; Load A with eight-bit write command.
ld (mmu_scr),A 	   ; Write A to sensor control register.

pop A            
pop F 
ret               

; ------------------------------------------------------------
; Configure the gyroscope.

gyr_config:
push F
push A             
ld A,gyr_cmd       ; Load A with command register address.
ld (mmu_sar),A     ; Write A to sensor address register.
ld A,gyr_susp      ; Load A with suspend mode command.
ld (mmu_slb),A     ; Write A to sensor low byte.
ld A,gy_wr8		   ; Load A with eight-bit write command.
ld (mmu_scr),A     ; Write A to sensor control register.
ld A,gyr_en        ; Check to see if gyroscope should be
and A,0xFF         ; enabled, and if so, enable it,
jp z,cfgy_suspend  ; otherwise don't.
ld A,gyr_normal    ; Load A with normal mode command.
ld (mmu_slb),A     ; Write A to sensor low byte.
ld A,gy_wr8		   ; Load A with eight-bit write command.
ld (mmu_scr),A     ; Write A to sensor control register.
cfgy_suspend:
ld A,gyr_rng       ; Load A with gyroscope range register address.
ld (mmu_sar),A     ; Write A to sensor adress register.
ld A,gyr_rng_hi    ; Load A with a gyroscope range value.
ld (mmu_slb),A     ; Write A to sensor low byte.
ld A,gy_wr8        ; Load A with eight-bit write command.
ld (mmu_scr),A     ; Wirte A to sensor control register.
pop A
pop F   
ret  

; ------------------------------------------------------------
; Accelerometer sample transmit routines.

xmit_acc_x:
push F
push A          
ld (mmu_xcn),A   ; Write the channel number
ld A,acc_x	     ; Load A with acc_x byte one address
ld (mmu_sar),A   ; Write address to sensor address register
ld A,acc_rd16    ; Load A with accelerometer sixteen-bit read command
ld (mmu_scr),A   ; Send command to sensor controller
ld A,sa_delay    ; Load A with the sensor access delay
dly A            ; and wait for sensor access to complete.
ld A,(mmu_shb)   ; Read sensor HI byte into A.
add A,off_16bs   ; Add offset to bring most negative value to zero.
ld (mmu_xhb),A   ; Write sensor HI byte to transmit HI byte
ld A,(mmu_slb)   ; Read sensor LO byte into A
ld (mmu_xlb),A   ; Write sensor LO byte to transmit LO byte
ld (mmu_xcr),A   ; Any write to transmit control register
ld A,tx_delay    ; Load A with the sample transmission delay
dly A            ; and wait for sample transmission to complete.
pop A           
pop F
ret              

xmit_acc_y:
push F
push A           
ld (mmu_xcn),A   ; Write the channel number
ld A,acc_y	     ; Load A with acc_y byte one address
ld (mmu_sar),A   ; Write address to sensor address register
ld A,acc_rd16    ; Load A with accelerometer sixteen-bit read command
ld (mmu_scr),A   ; Send command to sensor controller
ld A,sa_delay    ; Load A with the sensor access delay
dly A            ; and wait for sensor access to complete.
ld A,(mmu_shb)   ; Read sensor HI byte into A
add A,off_16bs   ; Add offset to negative values
ld (mmu_xhb),A   ; Write sensor HI byte to transmit HI byte
ld A,(mmu_slb)   ; Read sensor LO byte into A
ld (mmu_xlb),A   ; Write sensor LO byte to transmit LO byte
ld (mmu_xcr),A   ; Any write to transmit control register
ld A,tx_delay    ; Load A with the sample transmission delay
dly A            ; and wait for sample transmission to complete.
pop A            
pop F
ret              

xmit_acc_z:
push F
push A           
ld (mmu_xcn),A   ; Write the channel number
ld A,acc_z	     ; Load A with acc_z byte one address
ld (mmu_sar),A   ; Write address to sensor address register
ld A,acc_rd16    ; Load A with accelerometer sixteen-bit read command
ld (mmu_scr),A   ; Send command to sensor controller
ld A,sa_delay    ; Load A with the sensor access delay
dly A            ; and wait for sensor access to complete.
ld A,(mmu_shb)   ; Read sensor HI byte into A
add A,off_16bs   ; Add offset to negative values
push A           ; Move to 
pop B            ; B and negate
ld A,0xFF        ; by subtracting from
sub A,B          ; 255.
ld (mmu_xhb),A   ; Write to transmit HI byte.
ld A,(mmu_slb)   ; Read sensor LO byte.
ld (mmu_xlb),A   ; Write to transmit LO byte
ld (mmu_xcr),A   ; Initiate transmission.
ld A,tx_delay    ; Load sample transmission delay
dly A            ; and wait for sample transmission to complete.
pop A            
pop F            
ret              

; ------------------------------------------------------------
; Gyroscope sample transmit routines.

xmit_gy_x:
push F
push A     
ld (mmu_xcn),A   ; Write the channel number
ld A,gyr_x	     ; Load A with timer byte one address
ld (mmu_sar),A   ; Write address to sensor address register
ld A,gy_rd16     ; Load A with gyroscope sixteen-bit read command
ld (mmu_scr),A   ; Send command to sensor controller
ld A,sa_delay    ; Load A with the sensor access delay
dly A            ; and wait for sensor access to complete.
ld A,(mmu_shb)   ; Read sensor HI byte into A
add A,off_16bs   ; Add offset to negative values
ld (mmu_xhb),A   ; Write sensor HI byte to transmit HI byte
ld A,(mmu_slb)   ; Read sensor LO byte into A
ld (mmu_xlb),A   ; Write sensor LO byte to transmit LO byte
ld (mmu_xcr),A   ; Any write to transmit control register
ld A,tx_delay    ; Load A with the sample transmission delay
dly A            ; and wait for sample transmission to complete.
pop A   
pop F
ret 

xmit_gy_y:
push F
push A          
ld (mmu_xcn),A   ; Write the channel number
ld A,gyr_y	     ; Load A with timer byte one address
ld (mmu_sar),A   ; Write address to sensor address register
ld A,gy_rd16     ; Load A with gyroscope sixteen-bit read command
ld (mmu_scr),A   ; Send command to sensor controller
ld A,sa_delay    ; Load A with the sensor access delay
dly A            ; and wait for sensor access to complete.
ld A,(mmu_shb)   ; Read sensor HI byte into A
add A,off_16bs   ; Add offset to negative values
ld (mmu_xhb),A   ; Write sensor HI byte to transmit HI byte
ld A,(mmu_slb)   ; Read sensor LO byte into A
ld (mmu_xlb),A   ; Write sensor LO byte to transmit LO byte
ld (mmu_xcr),A   ; Any write to transmit control register
ld A,tx_delay    ; Load A with the sample transmission delay
dly A            ; and wait for sample transmission to complete.
pop A 
pop F          
ret     

xmit_gy_z:
push F
push A           
ld (mmu_xcn),A   ; Write the channel number
ld A,gyr_z	     ; Load A with timer byte one address
ld (mmu_sar),A   ; Write address to sensor address register
ld A,gy_rd16     ; Load A with gyroscope sixteen-bit read command
ld (mmu_scr),A   ; Send command to sensor controller
ld A,sa_delay    ; Load A with the sensor access delay
dly A            ; and wait for sensor access to complete.
ld A,(mmu_shb)   ; Read sensor HI byte into A
add A,off_16bs   ; Add offset to negative values
ld (mmu_xhb),A   ; Write sensor HI byte to transmit HI byte
ld A,(mmu_slb)   ; Read sensor LO byte into A
ld (mmu_xlb),A   ; Write sensor LO byte to transmit LO byte
ld (mmu_xcr),A   ; Any write to transmit control register
ld A,tx_delay    ; Load A with the sample transmission delay
dly A            ; and wait for sample transmission to complete.
pop A           
pop F
ret              

; ------------------------------------------------------------
; Calibrate the transmit clock frequency. Will leave the
; transmit clock disabled and cpu boost turned off.
calibrate_tck:
push F
push A           
push B   
ld A,0x00        ; Clear bit zero of A
ld (mmu_bcc),A   ; Disable CPU Clock Boost
ld (mmu_etc),A   ; Disable Transmit Clock
ld A,initial_tcd ; The initial value of transmit clock divisor
push A           ; Push divisor onto the stack
pop B            ; Store divisor in B
cal_tck_1:
dec B            ; Decrement the divisor
push B           ; Push divisor onto stack
pop A            ; Pop divisor into A
ld (mmu_tcd),A   ; Write divisor value to ring oscillator
ld A,0x01        ; Set bit zero of A
ld (mmu_etc),A   ; Enable the transmit clock
ld A,(mmu_tcf)   ; Read the transmit clock frequency
sub A,min_tcf    ; Subtract the minimum frequency
ld A,0x00        ; Clear bit zero of A
ld (mmu_etc),A   ; Disable Transmit Clock
jp np,cal_tck_1  ; Try smaller divisor
pop B            
pop A          
pop F
ret              

; ------------------------------------------------------------
; The interrupt routine. Transmits all required measurements,
; accelerometer first, then gyroscope if enabled. The sensor 
; axis order we retain for the gyroscope but we flip y and x 
; for the accelerometer so that the two sensor axes coincide 
; with respect to the device body.
interrupt:
push F              ; Save the flags onto the stack.
push A              ; Save A on stack

ld A,0x01           ; Set bit zero and
ld (mmu_tpr),A      ; write to test point register.
ld A,0x00           ; Clear bit zero and
ld (mmu_tpr),A      ; write to test point register.

ld A,0x01           ; Set bit zero to one.
ld (mmu_etc),A      ; Enable the transmit clock, TCK.
ld (mmu_bcc),A      ; Boost the CPU clock to TCK.

ld A,device_id      ; This device id is first channel number.
call xmit_acc_y     ; Transmit accelerometer y-axis.
inc A               ; Increment channel number.
call xmit_acc_x     ; Transmit accelerometer x-axis.
inc A               ; Increment channel number.
call xmit_acc_z     ; Transmit accelerometer z-axis.
inc A               ; Increment channel number.

ld A,gyr_en         ; If the gyroscope is enabled,
and A,0xFF          ; transmit its three coordinates,
jp z,int_gydis      ; otherwise don't.
call xmit_gy_x      ; Transmit gyroscope x-axis
inc A               ; Increment channel number.
call xmit_gy_y      ; Transmit gyroscope y-axis
inc A               ; Increment channel number.
call xmit_gy_z      ; Transmit gyroscope z-axis.
int_gydis:

ld A,0x00           ; Clear bit zero to zero.
ld (mmu_bcc),A      ; Move CPU back to slow RCK.
ld (mmu_etc),A      ; Stop the transmit clock.

ld A,0xFF           ; Set all bits to one and use to
ld (mmu_irst),A     ; reset all interrupts.

pop A               ; Restore A
pop F               ; Restore the flags.
rti

; ------------------------------------------------------------
; Initialize the device.
initialize:

; Initialize the stack pointer.
ld HL,mmu_sba
ld SP,HL

; Wait for a while. The power supplies must settle after entering
; standby mode, and the ring oscillator frequency is sensitive to
; the power supply voltage. We must let the gyroscope and accelerometer
; settle down also.
ld A,boot_delay  ; We want start_delay x 256 
push A           ; cycles of RCK = 32.768 kHz
pop B            ; before proceeding with execution.
pwr_up_lp:
ld A,0xFF        ; Load A with 255 to give the maximum eight bit
dly A            ; count, and wait this number of RCK periods.
dec B            ; Decremnent B until zero.
jp nz,pwr_up_lp

; Calibrate the transmit clock.
call calibrate_tck

; Set the low radio frequency for sample transmission
ld A,tx_frequency
ld (mmu_xfc),A

; Configure the gyroscope and accelerometer
call gyr_config
call acc_config

; Set interrupt timer interval and enable the timer interrupt to implement
; the sample period. The value we want to load into the interrup timer period 
; register is the sample period minus one, because the interrupt timer counts
; the value down to zero. So we load A with sample_period, then decrement. If
; sample_period is zero (0x00), the value we write is 255 (0xFF).
ld A,0xFF            ; Load A with ones
ld (mmu_irst),A      ; and reset all interrupts.
ld A,sample_period   ; Load A with the sample period,
dec A                ; and decrement to get the value
ld (mmu_itp),A       ; we write to timer period register.
ld A,0x01            ; Set bit zero of A to one and use
ld (mmu_imsk),A      ; to enable the timer interrupt.
; ------------------------------------------------------------

; The main program loops. The interrupts will be running 
; in the background, and they do all the work.
main:

ld A,(mmu_tpr)      ; Load the test point register.
or A,0x02           ; Set bit one and
ld (mmu_tpr),A      ; write to test point register.
and A,0xFD          ; Clear bit one and
ld (mmu_tpr),A      ; write to test point register.
ld A,255            ; Delay for 255 clock cycles.
dly A               ; so as to make the test pulse rare.
jp main             ; Repeat the main loop.

; ------------------------------------------------------------
