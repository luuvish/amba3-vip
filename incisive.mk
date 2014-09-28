#===============================================================================
#
# The MIT License (MIT)
#
# Copyright (c) 2014 Luuvish Hwang
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#===============================================================================
#
#   File         : incisive.mk
#   Author(s)    : luuvish (github.com/luuvish/amba3-vip)
#   Modifier     : luuvish (luuvish@gmail.com)
#   Descriptions : Makefile for Cadence Incisive Unified Simulator
#
#===============================================================================

CPP     = g++
CC      = gcc
AR      = ar
LD      = $(CC)
ASM     = nasm

VLOG    = ncvlog
VLIB    = ncelab
VSIM    = ncsim

CCFLAGS = -Wall -fPIC
LDFLAGS = -O3

NCFLAGS = -nocopyright -nolog

IUS_DIR = $(CDS_INST_DIR)/tools/include

SRC_DIR = ./src
DPI_DIR = .
RTL_DIR = .

OBJ_DIR = ./build/obj
LIB_DIR = ./build/sim

TARGETS =

RTL_LIB := ambalib
DPI_LIB := $(LIB_DIR)/dpi_amba3.so

DPI_SRCS := dpi_amba3.c
DPI_OBJS := $(addprefix $(LIB_DIR)/, $(DPI_SRCS:.c=.o))

AMBA3_SRCS := pkg_amba3.sv pkg_amba3_apb_if.sv pkg_amba3_axi_if.sv


.SUFFIXES: .c .cpp .asm .v .sv

.PHONY: clean

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) $(CCFLAGS) -I$(SRC_DIR) -o $@ -c $<

$(LIB_DIR)/%.o: $(DPI_DIR)/%.c
	$(CC) $(CCFLAGS) -I$(SRC_DIR) -I$(IUS_DIR) -o $@ -c $<

CHECK_DIRS = $(OBJ_DIR) $(LIB_DIR)

all: $(CHECK_DIRS) $(DPI_LIB) $(RTL_LIB)

clean:
	-rm -rf $(OBJ_DIR) $(LIB_DIR)

$(OBJ_DIR):
	@if [ ! -d $(OBJ_DIR) ]; then\
		mkdir -p $(OBJ_DIR);\
	fi

$(LIB_DIR):
	@if [ ! -d $(LIB_DIR) ]; then\
		mkdir -p $(LIB_DIR)/worklib;\
		mkdir -p $(LIB_DIR)/ambalib;\
	fi

$(DPI_LIB): $(DPI_OBJS)
	$(LD) $(LDFLAGS) -fPIC -g -shared -o $@ $^ -lm

ambalib: $(addprefix $(RTL_DIR)/, $(AMBA3_SRCS))
	$(VLOG) $(NCFLAGS) -sv -work ambalib +incdir+$(RTL_DIR) $^
