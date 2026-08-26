CC := $(CROSS_COMPILE)gcc
CFLAGS := -Wall -Werror -g

writer: writer.o
	$(CC) $(CFLAGS) -o writer writer.o

writer.o: writer.c
	$(CC) $(CFLAGS) -c writer.c

.PHONY: clean

clean:
	rm -f writer writer.o
