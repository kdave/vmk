# copied from Yelp/dumb-init Makefile and minimized only to make it build
SHELL=bash
CFLAGS=-std=gnu99 -static -s -Wall -Werror -O3

VERSION = 1.2.5

dumb-init: dumb-init.c VERSION.h
	$(CC) $(CFLAGS) -o dumb-init dumb-init.c

dumb-init-32: dumb-init.c VERSION.h
	$(CC) $(CFLAGS) -o dumb-init-32 dumb-init.c -m32

VERSION.h: Makefile
	echo '// THIS FILE IS AUTOMATICALLY GENERATED' > VERSION.h
	echo '// Run `make VERSION.h` to update it after modifying VERSION.' >> VERSION.h
	echo $(VERSION) > VERSION
	xxd -i VERSION >> VERSION.h
	rm VERSION

.PHONY: clean
clean:
	rm -rf dumb-init VERSION.h
