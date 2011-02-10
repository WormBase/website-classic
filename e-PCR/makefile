
CPP = g++
CFLAGS = -g

all : e-PCR

clean: 
	- rm *.o
	- rm e-PCR

install: e-PCR
	ginstall e-PCR /usr/local/bin

e-PCR : e-PCR.cxx stsmatch.o fasta-io.o util.o
	$(CPP) $(CFLAGS) -o e-PCR e-PCR.cxx stsmatch.o fasta-io.o util.o

stsmatch.o : stsmatch.cxx stsmatch.h util.h
	$(CPP) $(CFLAGS) -c stsmatch.cxx

fasta-io.o : fasta-io.cxx fasta-io.h util.h
	$(CPP) $(CFLAGS) -c fasta-io.cxx

util.o : util.cxx util.h
	$(CPP) $(CFLAGS) -c util.cxx

