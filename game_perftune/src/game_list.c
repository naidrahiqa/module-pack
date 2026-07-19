#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "game_list.h"

static void trim_line(char *s) {
    char *end;
    while (isspace((unsigned char)*s)) s++;
    if (*s == 0) return;
    end = s + strlen(s) - 1;
    while (end > s && isspace((unsigned char)*end)) end--;
    *(end + 1) = 0;
}

int game_list_load(game_list_t *list, const char *conf_path) {
    FILE *f;
    char line[MAX_PKG_LEN];
    int count = 0;

    strncpy(list->conf_path, conf_path, sizeof(list->conf_path) - 1);
    list->conf_path[sizeof(list->conf_path) - 1] = '\0';

    f = fopen(conf_path, "r");
    if (!f) {
        list->count = 0;
        return -1;
    }

    while (count < MAX_GAMES && fgets(line, sizeof(line), f)) {
        trim_line(line);
        if (line[0] == '\0' || line[0] == '#') continue;
        strncpy(list->packages[count], line, MAX_PKG_LEN - 1);
        list->packages[count][MAX_PKG_LEN - 1] = '\0';
        count++;
    }
    fclose(f);
    list->count = count;
    return count;
}

int game_list_contains(const game_list_t *list, const char *pkg) {
    int i;
    for (i = 0; i < list->count; i++) {
        if (strcmp(list->packages[i], pkg) == 0) return 1;
    }
    return 0;
}

int game_list_add(game_list_t *list, const char *pkg) {
    FILE *f;
    if (list->count >= MAX_GAMES) return -1;
    if (game_list_contains(list, pkg)) return 0;

    strncpy(list->packages[list->count], pkg, MAX_PKG_LEN - 1);
    list->packages[list->count][MAX_PKG_LEN - 1] = '\0';
    list->count++;

    f = fopen(list->conf_path, "a");
    if (f) {
        fprintf(f, "%s\n", pkg);
        fclose(f);
    }
    return 1;
}

int game_list_remove(game_list_t *list, const char *pkg) {
    int i, j;
    FILE *f;
    for (i = 0; i < list->count; i++) {
        if (strcmp(list->packages[i], pkg) == 0) break;
    }
    if (i >= list->count) return -1;

    for (j = i; j < list->count - 1; j++) {
        strcpy(list->packages[j], list->packages[j + 1]);
    }
    list->count--;

    f = fopen(list->conf_path, "w");
    if (f) {
        for (j = 0; j < list->count; j++) {
            fprintf(f, "%s\n", list->packages[j]);
        }
        fclose(f);
    }
    return 1;
}

void game_list_print(const game_list_t *list) {
    int i;
    for (i = 0; i < list->count; i++) {
        printf("  %d. %s\n", i + 1, list->packages[i]);
    }
}
