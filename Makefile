# Makefile for mailcheck.c (c) 2004 Bill Kibby <bill@bkibby.com>

prefix := /usr/local

CC=cc
//opts=-02
LDFLAGS=-L/usr/lib/mysql -lmysqlclient
CFLAGS=-I/usr/local/include
RM=rm -f

all : mailcheck

mailcheck : mailcheck.o
	$(CC) $(CFLAGS) $(OPTS) mailcheck.c -o mailcheck $(LDFLAGS)
	$(RM) mailcheck.o

clean:
	$(RM) *.o mailcheck core.* *~

dist: clean
	tar -czf psa_mailcheck.tar.gz ./*
