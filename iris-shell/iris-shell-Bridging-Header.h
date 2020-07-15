//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#include <CoreFoundation/CoreFoundation.h>
#include <histedit.h>

void EL_init(const char *argv0);

void EL_dispose(void);

CFStringRef EL_read(void);

void EL_setIndent(int n);

