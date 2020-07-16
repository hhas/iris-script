//
//  iris-shell.c
//  iris-shell
//
//  readline support
//

#include "iris-shell-Bridging-Header.h"


EditLine* el;
History* elHistory;
HistEvent elEvent;

#define PROMPT_BUFFER_SIZE (13)

char prompt[PROMPT_BUFFER_SIZE];

int indentDepth = -1;

char* EL_prompt(EditLine *e) {
    return prompt;
}


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


CFStringRef EL_read(void) {
    int count;
    const char* line = el_gets(el, &count);
    if (count > 0) { // -ve count indicates error
        if (count > 1) history(elHistory, &elEvent, H_ENTER, line);
        return CFStringCreateWithCString(NULL, line, kCFStringEncodingUTF8); // caller is responsible for releasing
    } else {
        return CFSTR("");
    }
}
