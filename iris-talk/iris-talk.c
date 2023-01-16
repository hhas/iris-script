//
//  iris-talk.c
//  iris-talk
//
//  readline support
//

#include "iris-talk-Bridging-Header.h"
#include <sys/ioctl.h>
#include <sys/ttycom.h>


EditLine* el;
History* elHistory;
HistEvent elEvent;


#define PROMPT_BUFFER_SIZE (13)

char prompt[PROMPT_BUFFER_SIZE];

char* EL_prompt(EditLine *e) {
    return prompt;
}


int indentDepth = -1;

void EL_setIndent(int n) {
    #define MAX_DEPTH (PROMPT_BUFFER_SIZE - 5)
    if (n != indentDepth) {
        if (n < 0) n = 0;
        indentDepth = n > MAX_DEPTH ? MAX_DEPTH : n;
        for (int i = 0; i < PROMPT_BUFFER_SIZE; i++) { prompt[i] = 0x20; }
        if (indentDepth == 0) { // ✎
            prompt[indentDepth+0] = 0xE2;
            prompt[indentDepth+1] = 0x9C;
            prompt[indentDepth+2] = 0x8E;
        } else { // …
            prompt[indentDepth+0] = 0xE2;
            prompt[indentDepth+1] = 0x80;
            prompt[indentDepth+2] = 0xA6;
        }
        prompt[indentDepth+3] = 0x20;
        prompt[indentDepth+4] = 0x00;
    }
}


void EL_init(const char *argv0) {
    el = el_init(argv0, stdin, stdout, stderr);
    el_set(el, EL_PROMPT, &EL_prompt);
    el_set(el, EL_EDITOR, "emacs");
    elHistory = history_init();
    history(elHistory, &elEvent, H_SETSIZE, 800);
    el_set(el, EL_HIST, history, elHistory);
}


void EL_dispose(void) {
    history_end(elHistory);
    el_end(el);
}

void EL_writeHistory(const char *line) {
    history(elHistory, &elEvent, H_ENTER, line);
}

//

// TO DO: if we want to colorize per-token during input, use el_getc() to read chars up to next space or linebreak and let main loop feed that immediately to parser

CFStringRef EL_readLine(void) {
    int count;
    const char *line = el_gets(el, &count);
    if (count > 0) { // -ve count indicates error; 0 = input canceled
        return CFStringCreateWithCString(NULL, line, kCFStringEncodingUTF8); // caller takes ownership
    } else {
        return CFSTR("");
    }
}

void EL_rewriteLine(const char *oldLine, const char *newLine) { // crude, but hopefully does the job
    struct winsize w;
    if (ioctl(fileno(stdout), TIOCGWINSZ, &w)) return;
    int linecount = 0; // oldLine includes trailing LF
    int offset = (int)strlen(EL_prompt(NULL));
    char c;
    int i = 0;
    while ((c = oldLine[i])) {
        if (c == '\x0a' || offset == w.ws_col) {
            linecount++;
            offset = 0;
        } else {
            offset++;
        }
        i++;
    }
    printf("\x1b[%iA\x1bJ", linecount); // move cursor up and delete to end of screen to remove inputted code
    printf("%s%s\n", EL_prompt(el), newLine); // reprint the prompt followed by the re-colored code
}
