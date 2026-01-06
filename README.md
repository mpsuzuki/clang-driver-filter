# filter-clang-link.sh
======================

## What is this?

This is a shell script to extract the command to be
executed by clang, and apply some filters to it before
real execution.  At present, this script is designed
for the linking phase, so only the last command is
dealt.

## Why?

Some version of Apple Clang tries to link the components
libraries of a Framework directly, and fails. To avoid
this incorrect behaviour, filter-out "-lsystem_xxx" from
the raw linker command to be executed by Clang compiler
driver.

Originally, Apple MacOSX shipped big libSystem.dylib as
single real library, but later it was divided into multiple
components, like components in Framework. However, some
versions of Apple Clang misakenly try to link the component
libraries directly, although the command line options do
not request such.  For example, you just request "-lSystem",
but some versions of Apple clang "kindly" interprets it to
"-lSystem -lsystem_pthread" if some of your object files are
recognized as "requesting PTHREAD functionalities".

Unfortunately, libsystem_pthread is not provided. Apple had
removed real dylib from their products for the customers,
and only libsystem_pthread.tbd is provided, which prohibits
to be linked directly.

Actually, users do not need to include "-lsystem_xxx".
"-lSystem" or "-framework System" deals libsystem_xxx.tbd
appropriately.

## What this does?

This script obtain the final command to be executed by
"clang -###", and exclude "-lsystem_xxx" in its result.

If the compiler cannot proceed to the execution stage,
like unknown options or missing object file etc, the
errors are displayed, and does not execute anything.

If the compiler is not Apple clang, no filters would be
applied.

## How to use this?

In the recipe in Makefile, you may write something like:

```
libXXX.dylib: obj1.o obj2.o obj3.o
	$(CC) $(CFLAGS) $(LDFLAGS) -dynamiclib -o $@ $^ 
```

You can do like:
```
LINK_WRAP ?= /path/to/somewhere/filter-clang-link.sh

libXXX.dylib: obj1.o obj2.o obj3.o
	$(LINK_WRAP) $(CC) $(CFLAGS) $(LDFLAGS) -dynamiclib -o $@ $^ 
```

## Scope of this script

You may want to use this script when you build an executable
from a source file immediately, like:

```
hello: hello.c
	$(CC) -o $@ $^
```

This script cannot help you, at present. `clang -###` would issue
multiple commands to be executed (assembling and linking, at least).
But this script ignores the outputs before the final commands,
regardless with whether they are information or commands.
