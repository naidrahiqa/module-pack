#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <ctype.h>
#include <android/log.h>
#include "cpu_pinner.h"

#define LOG_TAG "GamePerfTune"
#define BIG_CORES_MASK "c0"
#define ALL_CORES "0-7"
#define CPUSET_FOREGROUND "/dev/cpuset/foreground/cpus"
#define CPUSET_TOP_APP "/dev/cpuset/top-app/cpus"

static int is_game_process(const char *comm, const game_list_t *games) {
    int i;
    for (i = 0; i < games->count; i++) {
        const char *pkg = games->packages[i];
        const char *last_dot = strrchr(pkg, '.');
        const char *short_name = last_dot ? last_dot + 1 : pkg;
        if (strcasestr(comm, short_name)) return 1;
    }
    return 0;
}

static int write_file(const char *path, const char *value) {
    FILE *f = fopen(path, "w");
    if (!f) return -1;
    fprintf(f, "%s", value);
    fclose(f);
    return 0;
}

static int read_file(const char *path, char *buf, size_t bufsz) {
    FILE *f = fopen(path, "r");
    if (!f) return -1;
    if (fgets(buf, bufsz, f)) {
        buf[strcspn(buf, "\n")] = 0;
        fclose(f);
        return 0;
    }
    fclose(f);
    return -1;
}

int cpu_pin_game_pids(const game_list_t *games) {
    DIR *proc;
    struct dirent *ent;
    int pinned = 0;
    char comm_path[256];
    char cpuset_path[256];
    char comm[64];

    proc = opendir("/proc");
    if (!proc) return -1;

    while ((ent = readdir(proc)) != NULL) {
        if (!isdigit(ent->d_name[0])) continue;
        if (atoi(ent->d_name) < 2000) continue;

        snprintf(comm_path, sizeof(comm_path), "/proc/%s/comm", ent->d_name);
        if (read_file(comm_path, comm, sizeof(comm)) != 0) continue;
        if (comm[0] == '\0') continue;

        if (is_game_process(comm, games)) {
            snprintf(cpuset_path, sizeof(cpuset_path), "/proc/%s/cpuset", ent->d_name);
            if (write_file(cpuset_path, BIG_CORES_MASK) == 0) {
                __android_log_print(ANDROID_LOG_INFO, LOG_TAG,
                    "CPU: pinned PID %s (%s) -> big cores", ent->d_name, comm);
                pinned++;
            }
        }
    }
    closedir(proc);
    return pinned;
}

int cpu_restore_all(void) {
    char cur[64];

    if (read_file(CPUSET_FOREGROUND, cur, sizeof(cur)) == 0) {
        if (strcmp(cur, ALL_CORES) != 0) {
            write_file(CPUSET_FOREGROUND, ALL_CORES);
            __android_log_print(ANDROID_LOG_INFO, LOG_TAG,
                "CPU: restored foreground/cpus -> %s", ALL_CORES);
        }
    }
    if (read_file(CPUSET_TOP_APP, cur, sizeof(cur)) == 0) {
        if (strcmp(cur, ALL_CORES) != 0) {
            write_file(CPUSET_TOP_APP, ALL_CORES);
            __android_log_print(ANDROID_LOG_INFO, LOG_TAG,
                "CPU: restored top-app/cpus -> %s", ALL_CORES);
        }
    }
    return 0;
}
