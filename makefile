# Makefile
#

CC=g++
CFLAGS=-c
WFLAGS= -g

all: ospf_geni.cc
	g++ -std=c++0x ospf_geni.cc -o ospf_geni -lpthread -w

clean:
	rm -rf *.o
	rm -rf ospf
