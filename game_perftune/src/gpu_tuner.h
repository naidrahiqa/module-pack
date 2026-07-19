#ifndef GPU_TUNER_H
#define GPU_TUNER_H

typedef struct {
    int boost_freq;
    int upbound_freq;
    int ged_boost_enable;
    int gx_game_mode;
} gpu_state_t;

int gpu_save_state(gpu_state_t *state);
int gpu_apply_boost(const gpu_state_t *state);
int gpu_restore(const gpu_state_t *state);
int gpu_write_verify(const char *path, const char *value, const char *name);

#endif
