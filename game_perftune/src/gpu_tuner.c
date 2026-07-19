#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <android/log.h>
#include "gpu_tuner.h"

#define GPU_BOOST_PATH "/sys/module/ged/parameters/gpu_cust_boost_freq"
#define GPU_UPPER_PATH "/sys/module/ged/parameters/gpu_cust_upbound_freq"
#define GPU_GED_PATH   "/sys/module/ged/parameters/ged_boost_enable"
#define GPU_GAME_PATH  "/sys/module/ged/parameters/gx_game_mode"
#define GPU_MAX_FREQ   900000

static int read_int(const char *path) {
    FILE *f = fopen(path, "r");
    int val = 0;
    if (f) {
        fscanf(f, "%d", &val);
        fclose(f);
    }
    return val;
}

int gpu_write_verify(const char *path, const char *value, const char *name) {
    FILE *f;
    char buf[32];
    int ret = 0;

    f = fopen(path, "w");
    if (!f) {
        __android_log_print(ANDROID_LOG_ERROR, "GamePerfTune",
            "GPU: %s write OPEN FAIL", name);
        return -1;
    }
    fprintf(f, "%s", value);
    fclose(f);

    f = fopen(path, "r");
    if (f) {
        if (fgets(buf, sizeof(buf), f)) {
            buf[strcspn(buf, "\n")] = 0;
            if (strcmp(buf, value) == 0) {
                __android_log_print(ANDROID_LOG_INFO, "GamePerfTune",
                    "GPU: %s = %s OK", name, value);
                ret = 0;
            } else {
                __android_log_print(ANDROID_LOG_WARN, "GamePerfTune",
                    "GPU: %s FAIL (wrote %s, got %s)", name, value, buf);
                ret = -1;
            }
        }
        fclose(f);
    }
    return ret;
}

int gpu_save_state(gpu_state_t *state) {
    state->boost_freq = read_int(GPU_BOOST_PATH);
    state->upbound_freq = read_int(GPU_UPPER_PATH);
    state->ged_boost_enable = read_int(GPU_GED_PATH);
    state->gx_game_mode = read_int(GPU_GAME_PATH);
    __android_log_print(ANDROID_LOG_INFO, "GamePerfTune",
        "GPU state saved: boost=%d upper=%d ged=%d game=%d",
        state->boost_freq, state->upbound_freq,
        state->ged_boost_enable, state->gx_game_mode);
    return 0;
}

int gpu_apply_boost(const gpu_state_t *state) {
    char buf[32];
    (void)state;

    snprintf(buf, sizeof(buf), "%d", GPU_MAX_FREQ);
    gpu_write_verify(GPU_BOOST_PATH, buf, "gpu_cust_boost_freq");
    gpu_write_verify(GPU_UPPER_PATH, buf, "gpu_cust_upbound_freq");
    gpu_write_verify(GPU_GED_PATH, "1", "ged_boost_enable");
    gpu_write_verify(GPU_GAME_PATH, "1", "gx_game_mode");
    return 0;
}

int gpu_restore(const gpu_state_t *state) {
    char buf[32];

    snprintf(buf, sizeof(buf), "%d", state->boost_freq);
    gpu_write_verify(GPU_BOOST_PATH, buf, "gpu_cust_boost_freq");
    snprintf(buf, sizeof(buf), "%d", state->upbound_freq);
    gpu_write_verify(GPU_UPPER_PATH, buf, "gpu_cust_upbound_freq");
    gpu_write_verify(GPU_GAME_PATH, "0", "gx_game_mode");
    return 0;
}
