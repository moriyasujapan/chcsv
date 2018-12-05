#
#
#
all:
	./BUILD

install:	all
	@/bin/rm -f *.o *.c
	@/bin/cp chcsv $(ORACLE_HOME)/bin
	@chmod 755 $(ORACLE_HOME)/bin/chcsv

clean:
	@/bin/rm -f *.o *.c *.lis chcsv
