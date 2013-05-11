# Custom Makefile include file
# by Dionisis G. Kakoliris


ifeq ($(OS),Windows_NT)
  CPPFLAGS += -DWIN32
  ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
    CPPFLAGS += -DAMD64
  endif
  ifeq ($(PROCESSOR_ARCHITECTURE),x86)
    CPPFLAGS += -DIA32
  endif
else
  UNAME_S := $(shell uname -s)
  ifeq ($(UNAME_S),Linux)
    CPPFLAGS += -DLINUX
  endif
  ifeq ($(UNAME_S),Darwin)
    CPPFLAGS += -DOSX
  endif
  UNAME_P := $(shell uname -p)
  ifeq ($(UNAME_P),x86_64)
    CPPFLAGS += -DAMD64
  endif
  ifneq ($(filter %86,$(UNAME_P)),)
    CPPFLAGS += -DIA32
  endif
  ifneq ($(filter arm%,$(UNAME_P)),)
    CPPFLAGS += -DARM
  endif
endif


CAT = cat
RM = rm -f

CC = gcc
CPPFLAGS += -DNDEBUG
CFLAGS = -Wall -Wextra -O3
LDFLAGS =
SOFLAGS = -shared

AR = ar
ARFLAGS = rc

RANLIB = ranlib

OBJSUFFIX = .o
SOBJSUFFIX = .os
LIBPREFIX = lib
LIBSUFFIX = .a
ifeq ($(OS),Windows_NT)
  SOPREFIX =
  SOSUFFIX = .dll
else
  SOPREFIX = lib
  ifeq ($(UNAME_S),Darwin)
    SOSUFFIX = .dylib
  else
    SOSUFFIX = .so
  endif
endif
ifeq ($(OS),Windows_NT)
  EXESUFFIX = .exe
else
  EXESUFFIX =
endif
