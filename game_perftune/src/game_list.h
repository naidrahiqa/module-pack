#ifndef GAME_LIST_H
#define GAME_LIST_H

#define MAX_GAMES 128
#define MAX_PKG_LEN 256

typedef struct {
    char packages[MAX_GAMES][MAX_PKG_LEN];
    int count;
    char conf_path[256];
} game_list_t;

int game_list_load(game_list_t *list, const char *conf_path);
int game_list_contains(const game_list_t *list, const char *pkg);
int game_list_add(game_list_t *list, const char *pkg);
int game_list_remove(game_list_t *list, const char *pkg);
void game_list_print(const game_list_t *list);

#endif
