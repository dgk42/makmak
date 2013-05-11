# Custom Makefile include file
# by Dionisis G. Kakoliris


.PHONY = all clean distclean rebuild


all: $(LIB) $(SO) $(BINS)

%$(OBJSUFFIX): %.c
	$(CC) $(CPPFLAGS) -c $(CFLAGS) $<

%$(SOBJSUFFIX): %.c
	$(CC) $(CPPFLAGS) -c -fPIC $(CFLAGS) -o $@ $<

clean:
	$(RM) $(OBJS) $(SOBJS)

distclean: clean
	$(RM) $(LIB) $(SO) $(BINS)

rebuild: clean all
