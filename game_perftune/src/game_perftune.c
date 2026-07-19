#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>
#include <sys/stat.h>
#include <android/log.h>
#include "game_list.h"
#include "gpu_tuner.h"
#include "net_tuner.h"
#include "cpu_pinner.h"

#define LOG_TAG "GamePerfTune"
#define LOG_FILE "/data/local/tmp/game_perftune.log"
#define CONF_FILE "/data/local/tmp/game_perftune_state"
#define GAMES_CONF "/data/adb/modules/game_perftune/games.conf"
#define DISABLE_FLAG "/data/local/tmp/game_perftune_disable"
#define ACTIVE_FLAG "/data/local/tmp/game_perftune_active"
#define POLL_INTERVAL 3
#define DUMPSYS_TIMEOUT 5

static volatile sig_atomic_t reload_requested = 0;
static volatile sig_atomic_t running = 1;
static game_list_t games;
static gpu_state_t gpu_orig;
static net_state_t net_orig;
static int game_running = 0;

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
    if (sig == SIGHUP) {
        reload_requested = 1;
    } else if (sig == SIGTERM || sig == SIGINT) {
        running = 0;
    }
}

static int detect_foreground_package(void) {
    FILE *p;
    char buf[512];
    char pkg[256] = {0};

    p = popen("dumpsys window", "r");
    if (!p) return -1;

    while (fgets(buf, sizeof(buf), p)) {
        if (strstr(buf, "mCurrentFocus")) {
            char *start = strrchr(buf, ' ');
            if (start) {
                start++;
                char *end = strchr(start, '/');
                if (end) {
                    size_t len = end - start;
                    if (len < sizeof(pkg)) {
                        strncpy(pkg, start, len);
                        pkg[len] = '\0';
                    }
                }
            }
            break;
        }
    }
    pclose(p);

    if (pkg[0] == '\0') return 0;
    return game_list_contains(&games, pkg);
}

static void apply_boost(void) {
    log_msg("GAME DETECTED — applying boost");

    gpu_apply_boost(&gpu_orig);
    cpu_pin_game_pids(&games);
    net_apply_boost();

    system("cmd notification post -t 'Game PerfTune' '' 'Game detected — boost ON (GPU+Net+Pin)' >/dev/null 2>&1 &");
    game_running = 1;
}

static void restore_default(void) {
    log_msg("GAME CLOSED — restoring defaults");

    gpu_restore(&gpu_orig);
    cpu_restore_all();
    net_restore(&net_orig);

    system("cmd notification post -t 'Game PerfTune' '' 'Game closed — defaults restored' >/dev/null 2>&1 &");
    game_running = 0;
}

static void load_state(void) {
    FILE *f;
    f = fopen(CONF_FILE, "r");
    if (f) {
        fscanf(f, "%d|%d|%d|%d",
            &gpu_orig.boost_freq, &gpu_orig.upbound_freq,
            &net_orig.tcp_low_latency, &net_orig.tcp_slow_start_after_idle);
        net_orig.tcp_no_metrics_save = 0;
        fclose(f);
        log_msg("Loaded saved state");
    } else {
        gpu_save_state(&gpu_orig);
        net_save_state(&net_orig);
        f = fopen(CONF_FILE, "w");
        if (f) {
            fprintf(f, "%d|%d|%d|%d",
                gpu_orig.boost_freq, gpu_orig.upbound_freq,
                net_orig.tcp_low_latency, net_orig.tcp_slow_start_after_idle);
            fclose(f);
        }
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

int main(int argc, char *argv[]) {
    int is_game;
    struct sigaction sa;

    if (argc > 1 && strcmp(argv[1], "--base") == 0) {
        log_msg("Applying base network tuning");
        net_apply_base();
        mkdir(ACTIVE_FLAG, 0755);
        rmdir(ACTIVE_FLAG);
        return 0;
    }

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
    sigaction(SIGHUP, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGINT, &sa, NULL);

    if (game_list_load(&games, GAMES_CONF) < 0) {
        log_msg("ERROR: Cannot load games.conf");
        return 1;
    }

    {
        char msg[256];
        snprintf(msg, sizeof(msg), "Game PerfTune v2.0.0 daemon started (%d games, polling %ds)",
            games.count, POLL_INTERVAL);
        log_msg(msg);
    }

    load_state();

    while (running) {
        if (reload_requested) {
            reload_requested = 0;
            game_list_load(&games, GAMES_CONF);
            log_msg("Game list reloaded (SIGHUP)");
        }

        if (access(DISABLE_FLAG, F_OK) == 0) {
            if (game_running) restore_default();
            log_msg("Disable flag found, daemon stopping");
            break;
        }

        is_game = detect_foreground_package();

        if (is_game && !game_running) {
            apply_boost();
        } else if (!is_game && game_running) {
            restore_default();
        }

        sleep(POLL_INTERVAL);
    }

    return 0;
}
