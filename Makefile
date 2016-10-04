
# Turn on increased build verbosity by defining BUILD_VERBOSE in your main
# Makefile or in your environment. You can also use V=1 on the make command
# line.

ifeq ("$(origin V)", "command line")
BUILD_VERBOSE=$(V)
endif
ifndef BUILD_VERBOSE
BUILD_VERBOSE = 0
endif
ifeq ($(BUILD_VERBOSE),0)
Q = @
else
Q =
endif
# Since this is a new feature, advertise it
ifeq ($(BUILD_VERBOSE),0)
$(info Use make V=1 or set BUILD_VERBOSE in your environment to increase build verbosity.)
endif

BUILD ?= build

RM = rm
ECHO = @echo

CROSS_COMPILE = arm-none-eabi-

AS = $(CROSS_COMPILE)as
CC = $(CROSS_COMPILE)gcc
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy
SIZE = $(CROSS_COMPILE)size

TOP = ../../../../../..

BSP   	 = $(TOP)/Drivers/BSP/STM32469I-Discovery
HAL   	 = $(TOP)/Drivers/STM32F4xx_HAL_Driver
CMSIS 	 = $(TOP)/Drivers/CMSIS
FREERTOS = $(TOP)/Middlewares/Third_Party/FreeRTOS/Source

INC =  -I../Inc
INC += -I$(HAL)/Inc
INC += -I$(CMSIS)/Include
INC += -I$(CMSIS)/Device/ST/STM32F4xx/Include
INC += -I$(BSP)
INC += -I$(FREERTOS)/CMSIS_RTOS
INC += -I$(FREERTOS)/include
INC += -I$(FREERTOS)/portable/GCC/ARM_CM4F

S_SRC_DIRS  = ../SW4STM32

C_SRC_DIRS  = ../Src
C_SRC_DIRS += $(BSP)
C_SRC_DIRS += $(HAL)/Src
C_SRC_DIRS += $(FREERTOS)
C_SRC_DIRS += $(FREERTOS)/CMSIS_RTOS
C_SRC_DIRS += $(FREERTOS)/portable/MemMang
C_SRC_DIRS += $(FREERTOS)/portable/GCC/ARM_CM4F

CFLAGS_CORTEX_M4 = -mthumb -mtune=cortex-m4 -mabi=aapcs -mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard -fsingle-precision-constant -Wdouble-promotion
CFLAGS = $(INC) -D STM32F469xx -Wall $(CFLAGS_CORTEX_M4) $(COPT)

#Debugging/Optimization
ifeq ($(DEBUG), 1)
CFLAGS += -g -DPENDSV_DEBUG
COPT = -O0
else
COPT += -Os -DNDEBUG
endif

LDFLAGS = -Wl,-T,../SW4STM32/STM32469I_DISCOVERY/STM32F469NIHx_FLASH.ld,-Map=$(@:.elf=.map),--cref $(CFLAGS_CORTEX_M4)

OBJ = \
	build/startup_stm32f469xx.o \
	build/main.o \
	build/stm32f4xx_it.o \
	build/system_stm32f4xx.o \
	build/cmsis_os.o \
	build/tasks.o \
	build/timers.o \
	build/list.o \
	build/queue.o \
	build/heap_4.o \
	build/port.o \
	build/syscalls.o \
	build/stm32469i_discovery.o \
	build/stm32f4xx_hal.o \
	build/stm32f4xx_hal_cortex.o \
	build/stm32f4xx_hal_dma.o \
	build/stm32f4xx_hal_i2c.o \
	build/stm32f4xx_hal_gpio.o \
	build/stm32f4xx_hal_pwr_ex.o \
	build/stm32f4xx_hal_rcc.o \

all: $(BUILD)/flash.elf

define compile_c
$(ECHO) "CC $<"
$(Q)$(CC) $(CFLAGS) -c -MD -o $@ $<
@# The following fixes the dependency file.
@# See http://make.paulandlesley.org/autodep.html for details.
@cp $(@:.o=.d) $(@:.o=.P); \
  sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
      -e '/^$$/ d' -e 's/$$/ :/' < $(@:.o=.d) >> $(@:.o=.P); \
  rm -f $(@:.o=.d)
endef

$(OBJ): | $(BUILD)
$(BUILD):
	mkdir -p $@

vpath %.s $(S_SRC_DIRS)
$(BUILD)/%.o: %.s
	$(ECHO) "AS $<"
	$(Q)$(AS) -o $@ $<

vpath %.c $(C_SRC_DIRS)
$(BUILD)/%.o: %.c
	$(call compile_c)

pgm: $(BUILD)/flash.bin
	dfu-util -a 0 -D $^ -s 0x8000000:leave

$(BUILD)/flash.bin: $(BUILD)/flash.elf
	$(ECHO) "Creating $@"
	$(OBJCOPY) -O binary $^ $@

$(BUILD)/flash.elf: $(OBJ)
	$(ECHO) "LINK $@"
	$(Q)$(CC) $(LDFLAGS) -o $@ $(OBJ) $(LIBS)
	$(Q)$(SIZE) $@

pgm-stlink: $(BUILD)/flash.bin
	$(ECHO) "Writing $<"
	$(Q)st-flash --reset write $< 0x08000000



clean:
	$(RM) -rf $(BUILD)
.PHONY: clean

-include $(OBJ:.o=.P)
