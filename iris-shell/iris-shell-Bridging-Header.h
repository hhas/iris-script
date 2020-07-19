//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#include <CoreFoundation/CoreFoundation.h>
#include <histedit.h>

void EL_init(const char *argv0);

void EL_dispose(void);

CFStringRef EL_readLine(void);

void EL_setIndent(int n);

char* EL_prompt(EditLine *e);

void EL_writeHistory(const char *line);

void EL_rewriteLine(const char *oldLine, const char *newLine);
