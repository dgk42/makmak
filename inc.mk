# Makefile includes

UNAME := $(shell uname)

ifeq ($(UNAME),Darwin)
  CP = rsync -u
else
  CP = cp -u
endif
RM = rm -f
MKDIR = mkdir -p
ifdef COMSPEC
  GREP = grep
else
  GREP = grep --color=auto
endif
SED = sed
WC = wc -l
SORT = sort -n
TESTEXISTSDIR = test -d
TR = tr
SHELLORELSE = ||
ifdef COMSPEC
  REMOVE_NEWL_AND_BACKSLASH = $(SED) ':a;N;$!ba;s/[\n\\]//g'
else
  REMOVE_NEWL_AND_BACKSLASH = $(TR) '\n\\' ' '
endif


TARGET = debug
JOBS = 1

OBJ = .o
SOBJ = .os
STATICLIB = .a
ifeq ($(UNAME),Linux)
  EXE =
  SO = .so
endif
ifeq ($(UNAME),Darwin)
  EXE =
  SO = .dylib
endif
ifdef COMSPEC
  EXE = .exe
  SO = .dll
endif
ifeq ($(TARGET),debug)
  PRE_EXT = _dbg
endif
ifeq ($(TARGET),ndebug)
  PRE_EXT =
endif
OBJ_EXT = $(PRE_EXT)$(OBJ)
SOBJ_EXT = $(PRE_EXT)$(SOBJ)
BIN_PREFIX =
BIN_SUFFIX = $(PRE_EXT)$(EXE)
STATICLIB_PREFIX = lib
STATICLIB_SUFFIX = $(PRE_EXT)$(STATICLIB)
SHAREDLIB_PREFIX = lib
SHAREDLIB_SUFFIX = $(PRE_EXT)$(SO)


MAKEINCDIR = $(dir $(lastword $(MAKEFILE_LIST)))
OUTBASEDIR = $(MAKEINCDIR)
OUTBUILDDIR = $(OUTBASEDIR)build
OUTOBJDIR = $(OUTBASEDIR)obj/$(PROJ)
ININCDIR = $(OUTBUILDDIR)/inc
OUTINCDIR = $(ININCDIR)/$(PROJ)
OUTBINDIR = $(OUTBUILDDIR)/bin
OUTSTATICLIBDIR = $(OUTBUILDDIR)/lib
OUTSHAREDLIBDIR = $(OUTBINDIR)
TESTDIRS = $(OUTOBJDIR) $(OUTINCDIR) $(OUTBINDIR) \
  $(OUTSTATICLIBDIR) $(OUTSHAREDLIBDIR)


INCDIRS += $(ININCDIR)
LIBDIRS += $(OUTSHAREDLIBDIR) $(OUTSTATICLIBDIR)

MAKE = make -C
CC = gcc -pipe
CFLAGS = -Wall -Wextra -pedantic
ifeq ($(TARGET),debug)
  CFLAGS += -g
  CPPFLAGS = -DDEBUG_PRINTOUT
endif
ifeq ($(TARGET),ndebug)
  CFLAGS += -O3 -ffast-math
  CPPFLAGS = -DNDEBUG
endif
INCFLAGS = $(INCDIRS:%=-I%)
CPPFLAGS += $(CPPFLAGSEXTRA) $(INCFLAGS)
CFLAGS += $(CFLAGSEXTRA)
#ifeq ($(UNAME),Linux)
#  SOFLAGS = -Wl,-rpath,'$$ORIGIN' -Wl,-z,origin
#endif
LIBFLAGS = $(LIBDIRS:%=-L%) $(LIBFLAGSEXTRA)
ifeq ($(UNAME),Darwin)
  ifeq ($(TARGET),ndebug)
	LDFLAGS = -Xlinker -unexported_symbol -Xlinker "*" \
	  $(LIBS:%=-l%$(PRE_EXT)) $(LDFLAGSEXTRA)
  else
	LDFLAGS = $(LIBS:%=-l%$(PRE_EXT)) $(LDFLAGSEXTRA)
  endif
else
  LDFLAGS = $(LIBS:%=-l%$(PRE_EXT)) $(LDFLAGSEXTRA)
endif
AR = ar
ARFLAGS = rcs
ifdef COMSPEC
  RANLIB = ranlib
endif
ifeq ($(UNAME),Darwin)
  STRIP = strip -Sx
else
  STRIP = strip -s
endif


SRCS = $(MODULES:%=%.c) $(UNITS:%=%.c)
OBJS = $(SRCS:%.c=$(OUTOBJDIR)/%$(OBJ_EXT))
SOBJS = $(SRCS:%.c=$(OUTOBJDIR)/%$(SOBJ_EXT))
BINS = $(UNITS:%=$(OUTBINDIR)/%$(BIN_SUFFIX))
HDRS = $(HEADERS:%=$(OUTINCDIR)/%.h) $(UNITS:%=$(OUTINCDIR)/%.h)

define bin_name
  $(OUTBINDIR)/$(BIN_PREFIX)$1$(BIN_SUFFIX)
endef

define staticlib_name
  $(OUTSTATICLIBDIR)/$(STATICLIB_PREFIX)$1$(STATICLIB_SUFFIX)
endef

define sharedlib_name
  $(OUTSHAREDLIBDIR)/$(SHAREDLIB_PREFIX)$1$(SHAREDLIB_SUFFIX)
endef

ifdef OUTSTATICLIB
  TARGETSTATICLIB = $(call staticlib_name,$(OUTSTATICLIB))
endif
ifdef STATICLIBS-DEPS
  LSTATICLIBS-DEPS = $(foreach i,$(STATICLIBS-DEPS),\
	$(call staticlib_name,$(i)))
endif
ifdef OUTSHAREDLIB
  TARGETSHAREDLIB = $(call sharedlib_name,$(OUTSHAREDLIB))
  TARGETSONAME = $(SHAREDLIB_PREFIX)$(OUTSHAREDLIB)$(SHAREDLIB_SUFFIX)
endif
ifdef OUTBIN
  TARGETBIN = $(call bin_name,$(OUTBIN))
endif


define dir_template
  $(eval $(shell $(TESTEXISTSDIR) $1 $(SHELLORELSE) $(MKDIR) $1))
endef

define proj_template
  $1-xxx:
	@echo
	$(MAKE) $1 -j $(JOBS) $(MAKECMDGOALS) \
	  TARGET=$(TARGET) MAKEINCDIR=$(addsuffix ../,$(MAKEINCDIR))
	@echo
endef

define c_modules_template
  $(eval \
	$(shell $(CC) $(INCFLAGS) -MM -MT '$(OUTOBJDIR)/$1$(OBJ_EXT)' $1.c | \
	  $(REMOVE_NEWL_AND_BACKSLASH)))
endef

define c_units_template
  $(call c_modules_template,$1)
  $(OUTBINDIR)/$1$(BIN_SUFFIX): $1.c $(OUTOBJDIR)/$1$(OBJ_EXT) \
	$(2:%=$(OUTOBJDIR)/%$(OBJ_EXT)) $(LSTATICLIBS-DEPS)
	$(call build_c_bin,$(OUTBINDIR)/$1$(BIN_SUFFIX),\
	  $1.c $(2:%=$(OUTOBJDIR)/%$(OBJ_EXT)))
  ifeq ($(TARGET),ndebug)
	$(STRIP) $(OUTBINDIR)/$1$(BIN_SUFFIX)
  endif
endef

define build_c_bin
	$(CC) $(CPPFLAGS) -DT_UTST $(CFLAGS) -o $1 $2 $(LIBFLAGS) $(LDFLAGS)
endef

define build_c_so
	$(CC) $(CFLAGS) -o $2 $3 -shared \
	  -Wl,-soname,$1 $(SOFLAGS)
endef

define build_c_so_darwin
	$(CC) $(CFLAGS) -o $2 $3 -shared \
	  -Wl,-dylib_install_name -Wl,$1 $(SOFLAGS)
endef


.PHONY: pre pre2 all help clean distclean rebuild count-ln


%$(OBJ_EXT): %.c
	$(CC) $(CPPFLAGS) -c $(CFLAGS) -o $@ $<

$(OUTOBJDIR)/%$(OBJ_EXT): %.c
	$(CC) $(CPPFLAGS) -c $(CFLAGS) -o $@ $<

$(OUTOBJDIR)/%$(SOBJ_EXT): %.c
	$(CC) $(CPPFLAGS) -c -fPIC $(CFLAGS) -o $@ $<

$(OUTINCDIR)/%.h: %.h
	$(CP) $< $@


# target: all - Default target. Builds binaries.
all: pre2 $(SUBPROJ:%=%-xxx) \
  $(BINS) $(TARGETSTATICLIB) $(TARGETSHAREDLIB) $(TARGETBIN) $(HDRS)

# target: help - Display callable targets.
help:
	@$(GREP) "^# target:" $(lastword $(MAKEFILE_LIST))

# target: clean - Cleans intermediate files.
clean: pre $(SUBPROJ:%=%-xxx)
	$(RM) $(OBJS) $(SOBJS) *~ core

# target: distclean - Cleans intermediate files + target binaries.
distclean: pre $(SUBPROJ:%=%-xxx) clean
	$(RM) $(HDRS) $(BINS) *.bak
	$(RM) $(TARGETBIN) $(TARGETSTATICLIB) $(TARGETSHAREDLIB) *.log

# target: rebuild - Rebuilds project (distclean + all).
rebuild: pre $(SUBPROJ:%=%-xxx) distclean all

# target: count-ln - Count source LOC.
count-ln: pre $(SUBPROJ:%=%-xxx)
	@$(WC) *.c *.cpp *.h *.hpp | $(SORT)

pre:
$(foreach i,$(TESTDIRS),\
  $(eval $(call dir_template,$(i))))
$(foreach i,$(SUBPROJ),\
  $(eval $(call proj_template,$(i))))

pre2: pre
$(foreach i,$(MODULES),\
  $(eval $(call c_modules_template,$(i))))
$(foreach i,$(UNITS),\
  $(eval $(call c_units_template,$(i),$($(i)-deps))))


$(TARGETSTATICLIB): $(OBJS)
	$(AR) $(ARFLAGS) $@ $^
  ifdef RANLIB
	$(RANLIB) $@
  endif

$(TARGETSHAREDLIB): $(SOBJS)
  ifeq ($(UNAME),Darwin)
	$(call build_c_so_darwin,$(TARGETSONAME),$@,$^ $(LSTATICLIBS-DEPS))
  else
	$(call build_c_so,$(TARGETSONAME),$@,$^)
  endif
  ifeq ($(TARGET),ndebug)
	$(STRIP) $@
  endif

$(TARGETBIN): $(OBJS) $(LSTATICLIBS-DEPS)
	$(call build_c_bin,$@,$(OBJS))
  ifeq ($(TARGET),ndebug)
	$(STRIP) $@
  endif
