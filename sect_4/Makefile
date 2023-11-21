PRGNAME := hello
ARCH = arm-none-eabi

LIBAEABI := 0

SRCROOTDIR := ../../part_2/sect_4
vpath %.c $(SRCROOTDIR)/application:$(SRCROOTDIR)/boot:$(SRCROOTDIR)/kernel
TOOLDIR := ../tools
BLDDIR := ./build
EXEFILE = $(BLDDIR)/$(PRGNAME)

CC = $(ARCH)-gcc
LD = $(ARCH)-ld
SIZE = $(ARCH)-size
E2U = $(TOOLDIR)/elf2uf2

CFLAGS = -Wall -march=armv6-m -mthumb -ffreestanding
CFLAGS += -I$(SRCROOTDIR)/include
CFLAGS += -g3 -O0
ifeq ($(MAKECMDGOALS),preproc)
	CFLAGS += -E
else
	CFLAGS += -MMD -MP
endif

LFLAGS = -nostartfiles -nostdlib
LFLAGS += -Wl,-Map,$(EXEFILE).map,--gc-sections,-T,$(SRCROOTDIR)/linker/pico_memmap.ld
LLIBS =

ifneq ($(LIBAEABI),0)
	LIBAEABI_DIR := ../libs
	LIBAEABI_A = $(LIBAEABI_DIR)/libaeabi-cortexm0.a
	ifeq ($(wildcard $(LIBAEABI_A)), $(LIBAEABI_A))
		LFLAGS += -L$(LIBAEABI_DIR)
		LLIBS += -laeabi-cortexm0
	endif
else
	LLIBS += -lgcc
endif

OBJDIR = $(BLDDIR)/obj
SRCDIRS = $(shell find $(SRCROOTDIR) -type d)
SRCS = $(foreach dir,$(SRCDIRS),$(wildcard $(dir)/*.c))
OBJS = $(addprefix $(OBJDIR)/,$(notdir $(SRCS)))
OBJS := $(patsubst %.c,%.o,$(OBJS))
DEPS = $(OBJS:.o=.d)

PPDIR = $(BLDDIR)/preproc
PPS = $(addprefix $(PPDIR)/,$(notdir $(SRCS)))
PPS := $(patsubst %.c,%.p,$(PPS))

#$(info SRCS = $(SRCS))
#$(info OBJS = $(OBJS))
#$(info DEPS = $(DEPS))
#$(info PPS = $(PPS))

.PHONY: all preproc clean

all: $(EXEFILE).uf2

$(EXEFILE).uf2: $(OBJS)
	$(CC) -o $(EXEFILE).elf $(LFLAGS) $^ $(LLIBS)
	$(SIZE) $(EXEFILE).elf
ifeq ($(wildcard $(E2U)), $(E2U))
	$(E2U) $(EXEFILE).elf $(EXEFILE).uf2
endif

$(OBJDIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -o $@ -c $<

preproc: $(PPS)

$(PPDIR)/%.p: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -o $@ -c $<

clean:
	rm -rf $(BLDDIR)

-include $(DEPS)
