# stm32cubef4-freertos
Makefile for the FreeRTOS example using the STM32F469 Discovery board

To use:

Grab a copy of the STM32CubeF4 code from here: http://www.st.com/web/en/catalog/tools/PF259243#
I tested with version 1.13.0.

Note that the latest version will probably be different from the version number below
(so update your path accordingly).

```
cd STM32Cube_FW_F4_V1.13.0/Projects/STM32469I-Discovery/Applications/FreeRTOS/FreeRTOS_ThreadCreation
git clone https://github.com/dhylands/stm32cubef4-freertos.git gcc
cd gcc
make
```

I used the arm-none-eabi toolchain from: https://launchpad.net/gcc-arm-embedded/
I happened to have the 4.9.3 version of gcc installed, although this generally
doesn't matter too much.

I was building using Ubuntu 16.04, and I flashed my 469 Discovery board using
the st-flash tool from: https://github.com/texane/stlink

```
make pgm-stlink
```

You can also power the board using the USER USB conenctor and flash it via DFU.
Move the power jumper (JP2) from STLK to USB, and plug a micro USB connector
into the "USER USB" plug (opposite end of the board from the mini USB connector
used for stlink).

Then connect BOOT0 to 3.3v by shorting the 2 pads of R150 (an
unpopulated resistor near pin 1 of the STM32F469 processor) and pressing
the RESET button. Once you can see the board in DFU mode, lsusb will show a line
of: 
```
Bus 005 Device 012: ID 0483:df11 STMicroelectronics STM Device in DFU Mode
```
then you can use:
```
make pgm
```
This will use dfu-util (from: http://dfu-util.sourceforge.net/) to flash the
device.

