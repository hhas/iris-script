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


char* EL_prompt(EditLine *e) {
    return "✎ ";
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
        history(elHistory, &elEvent, H_ENTER, line);
        return CFStringCreateWithCString(NULL, line, kCFStringEncodingUTF8); // caller is responsible for releasing
    } else {
        return CFSTR("");
    }
}
