#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>
#include <sys/stat.h>
#include <android/log.h>

#define LOG_TAG "UIEnhance"
#define LOG_FILE "/data/local/tmp/ui_enhance.log"
#define DISABLE_FLAG "/data/local/tmp/ui_enhance_disable"
#define STATS_FILE "/data/local/tmp/ui_enhance_stats"
#define POLL_INTERVAL 2
#define TUNE_INTERVAL 30

static volatile sig_atomic_t running = 1;

static void log_msg(const char *msg) {
    FILE *f;
    time_t now;
    struct tm *t;
    char buf[256];

    now = time(NULL);
    t = localtime(&now);
    snprintf(buf, sizeof(buf), "[%02d-%02d %02d:%02d:%02d] %s\n",
        t->tm_mon + 1, t->tm_mday, t->tm_hour, t->tm_min, t->tm_sec, msg);

    f = fopen(LOG_FILE, "a");
    if (f) {
        fputs(buf, f);
        fclose(f);
    }
    __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "%s", msg);
}

static void handle_signal(int sig) {
    if (sig == SIGTERM || sig == SIGINT) {
        running = 0;
    }
}

static int is_boot_completed(void) {
    FILE *p;
    char buf[64] = {0};
    p = popen("getprop sys.boot_completed", "r");
    if (p) {
        fgets(buf, sizeof(buf), p);
        pclose(p);
        buf[strcspn(buf, "\n")] = '\0';
        return strcmp(buf, "1") == 0;
    }
    return 0;
}

static long read_sysfs_long(const char *path) {
    FILE *f;
    long val = -1;
    f = fopen(path, "r");
    if (f) {
        fscanf(f, "%ld", &val);
        fclose(f);
    }
    return val;
}

static int read_frame_stats(long *fps, long *janky) {
    FILE *p;
    char buf[1024];
    long total_frames = 0;
    long jank_frames = 0;
    int found = 0;

    *fps = 0;
    *janky = 0;

    p = popen("dumpsys SurfaceFlinger --latency", "r");
    if (!p) return -1;

    while (fgets(buf, sizeof(buf), p)) {
        char *nl;
        nl = strchr(buf, '\n');
        if (nl) *nl = '\0';

        if (strstr(buf, " refresh-rate")) {
            float rate = 0;
            if (sscanf(buf, " refresh-rate: %f", &rate) == 1) {
                *fps = (long)rate;
                found = 1;
            }
        }
        if (strstr(buf, "Total frames rendered")) {
            sscanf(buf, "Total frames rendered: %ld", &total_frames);
        }
        if (strstr(buf, "Janky frames")) {
            sscanf(buf, "Janky frames: %ld", &jank_frames);
        }
    }
    pclose(p);

    *janky = jank_frames;

    if (*fps == 0 && total_frames > 0) {
        *fps = total_frames > 0 ? 60 : 0;
    }

    return found ? 0 : -1;
}

static int get_display_fps(void) {
    FILE *p;
    char buf[256] = {0};
    int fps = 60;

    p = popen("dumpsys display", "r");
    if (p) {
        while (fgets(buf, sizeof(buf), p)) {
            if (strstr(buf, "mActiveMode")) {
                float rate = 0;
                if (sscanf(buf, "mActiveMode=%*d, width=%*d, height=%*d, fps=%f", &rate) == 1) {
                    fps = (int)rate;
                    break;
                }
            }
        }
        pclose(p);
    }
    return fps;
}

static void apply_animation_tuning(void) {
    system("resetprop WindowManager_animation_scale 1.0");
    system("resetprop WindowManager_transition_animation_scale 1.0");
    system("resetprop WindowManager_duration_scale 1.0");
    system("resetprop ro.config.animation_scale 1.0");
    system("resetprop persist.sys.animation_scale 1.0");
}

static void apply_rendering_tuning(void) {
    system("resetprop persist.sys.ui.hw true");
    system("resetprop debug.hwui.renderer skiagl");
    system("resetprop debug.hwui.show_dirty_regions false");
    system("resetprop ro.config.disable_hw_accel false");
}

static void apply_surfaceflinger_tuning(void) {
    system("resetprop ro.surface_flinger.max_frame_buffer_acquired_buffers 3");
    system("resetprop ro.surface_flinger.running_without_sync_framework false");
    system("resetprop ro.surface_flinger.use_hwc_for_vsync true");
    system("resetprop viewpointer.debug.display_raw_orientation true");
}

static void apply_all_tuning(void) {
    apply_animation_tuning();
    apply_rendering_tuning();
    apply_surfaceflinger_tuning();
}

static void write_stats(long fps, long jank_total, int drop_count) {
    FILE *f;
    f = fopen(STATS_FILE, "w");
    if (f) {
        fprintf(f, "fps=%ld\njank_total=%ld\ndrops=%d\n", fps, jank_total, drop_count);
        fclose(f);
    }
}

static int count_frame_drops(long *prev_total, long cur_jank) {
    int drops = 0;
    if (cur_jank > *prev_total) {
        drops = (int)(cur_jank - *prev_total);
    }
    *prev_total = cur_jank;
    return drops;
}

int main(int argc, char *argv[]) {
    struct sigaction sa;
    long fps = 0;
    long jank_total = 0;
    long prev_jank = 0;
    int drop_count = 0;
    int tune_countdown = 0;
    int display_fps;

    if (access(DISABLE_FLAG, F_OK) == 0) {
        return 0;
    }

    while (!is_boot_completed()) {
        sleep(2);
    }
    sleep(8);

    if (access(DISABLE_FLAG, F_OK) == 0) {
        return 0;
    }

    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = handle_signal;
    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGINT, &sa, NULL);

    log_msg("UI Enhancement v1.0.0 daemon started");

    display_fps = get_display_fps();
    {
        char msg[128];
        snprintf(msg, sizeof(msg), "Display refresh rate: %dHz", display_fps);
        log_msg(msg);
    }

    apply_all_tuning();
    log_msg("Initial tuning applied");

    while (running) {
        if (access(DISABLE_FLAG, F_OK) == 0) {
            log_msg("Disable flag found, daemon stopping");
            break;
        }

        if (read_frame_stats(&fps, &jank_total) == 0) {
            int drops = count_frame_drops(&prev_jank, jank_total);
            if (drops > 0) {
                drop_count += drops;
                char msg[256];
                snprintf(msg, sizeof(msg), "Frame drop detected: %d (total: %d)", drops, drop_count);
                log_msg(msg);
            }
            write_stats(fps, jank_total, drop_count);
        }

        tune_countdown++;
        if (tune_countdown >= TUNE_INTERVAL) {
            tune_countdown = 0;
            apply_all_tuning();
            {
                char msg[128];
                snprintf(msg, sizeof(msg), "Tuning re-applied (fps=%ld, drops=%d)", fps, drop_count);
                log_msg(msg);
            }
        }

        sleep(POLL_INTERVAL);
    }

    log_msg("UI Enhancement daemon stopped");
    return 0;
}
