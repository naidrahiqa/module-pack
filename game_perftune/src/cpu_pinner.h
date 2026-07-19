#ifndef CPU_PINNER_H
#define CPU_PINNER_H

#include "game_list.h"

int cpu_pin_game_pids(const game_list_t *games);
int cpu_restore_all(void);

#endif
