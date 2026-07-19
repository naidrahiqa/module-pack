#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <android/log.h>
#include "net_tuner.h"

#define TCP_LL_PATH    "/proc/sys/net/ipv4/tcp_low_latency"
#define TCP_SSAI_PATH  "/proc/sys/net/ipv4/tcp_slow_start_after_idle"
#define TCP_NMS_PATH   "/proc/sys/net/ipv4/tcp_no_metrics_save"
#define TCP_RMEM_PATH  "/proc/sys/net/ipv4/tcp_rmem"
#define TCP_WMEM_PATH  "/proc/sys/net/ipv4/tcp_wmem"
#define TCP_RMAX_PATH  "/proc/sys/net/core/rmem_max"
#define TCP_WMAX_PATH  "/proc/sys/net/core/wmem_max"

#define LOG_TAG "GamePerfTune"

static int read_int(const char *path) {
    FILE *f = fopen(path, "r");
    int val = 0;
    if (f) {
        fscanf(f, "%d", &val);
        fclose(f);
    }
    return val;
}

static int write_verify(const char *path, const char *value, const char *name) {
    FILE *f;
    char buf[64];
    int ret = 0;

    f = fopen(path, "w");
    if (!f) {
        __android_log_print(ANDROID_LOG_ERROR, LOG_TAG,
            "NET: %s write OPEN FAIL", name);
        return -1;
    }
    fprintf(f, "%s", value);
    fclose(f);

    f = fopen(path, "r");
    if (f) {
        if (fgets(buf, sizeof(buf), f)) {
            buf[strcspn(buf, "\n")] = 0;
            if (strcmp(buf, value) == 0) {
                __android_log_print(ANDROID_LOG_INFO, LOG_TAG,
                    "NET: %s = %s OK", name, value);
                ret = 0;
            } else {
                __android_log_print(ANDROID_LOG_WARN, LOG_TAG,
                    "NET: %s FAIL (wrote %s, got %s)", name, value, buf);
                ret = -1;
            }
        }
        fclose(f);
    }
    return ret;
}

int net_save_state(net_state_t *state) {
    state->tcp_low_latency = read_int(TCP_LL_PATH);
    state->tcp_slow_start_after_idle = read_int(TCP_SSAI_PATH);
    state->tcp_no_metrics_save = read_int(TCP_NMS_PATH);
    __android_log_print(ANDROID_LOG_INFO, LOG_TAG,
        "NET state saved: ll=%d ssai=%d nms=%d",
        state->tcp_low_latency, state->tcp_slow_start_after_idle,
        state->tcp_no_metrics_save);
    return 0;
}

int net_apply_boost(void) {
    write_verify(TCP_LL_PATH, "1", "tcp_low_latency");
    write_verify(TCP_SSAI_PATH, "0", "tcp_slow_start_after_idle");
    write_verify(TCP_NMS_PATH, "1", "tcp_no_metrics_save");
    return 0;
}

int net_restore(const net_state_t *state) {
    char buf[32];

    snprintf(buf, sizeof(buf), "%d", state->tcp_low_latency);
    write_verify(TCP_LL_PATH, buf, "tcp_low_latency");
    snprintf(buf, sizeof(buf), "%d", state->tcp_slow_start_after_idle);
    write_verify(TCP_SSAI_PATH, buf, "tcp_slow_start_after_idle");
    snprintf(buf, sizeof(buf), "%d", state->tcp_no_metrics_save);
    write_verify(TCP_NMS_PATH, buf, "tcp_no_metrics_save");
    return 0;
}

int net_apply_base(void) {
    write_verify(TCP_RMEM_PATH, "4096 87380 6291456", "tcp_rmem");
    write_verify(TCP_WMEM_PATH, "4096 65536 6291456", "tcp_wmem");
    write_verify(TCP_RMAX_PATH, "65536 131072 262144", "rmem_max");
    write_verify(TCP_WMAX_PATH, "65536 131072 262144", "wmem_max");
    return 0;
}
