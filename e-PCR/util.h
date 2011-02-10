#ifndef __util_h__
#define __util_h__

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>

#ifndef bool
#define bool int
#endif

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE 
#define FALSE 0
#endif


bool __MemAlloc(void **ptr, int size);
bool __MemResize(void **ptr, int newsize);
bool __MemDealloc(void **ptr);

#define MemAlloc(x,y)     __MemAlloc((void**)&(x),(y))
#define MemResize(x,y)    __MemResize((void**)&(x),(y))
#define MemDealloc(x)     __MemDealloc((void**)&(x))

void PrintError(const char *message);
void FatalError(const char *message);

#endif
