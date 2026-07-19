#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>
#include <errno.h>
#include <sys/stat.h>
#include <android/log.h>

#define LOG_TAG "BatteryFix"
#define LOG_FILE "/data/local/tmp/battery_fix.log"
#define DISABLE_FLAG "/data/local/tmp/battery_fix_disable"
#define POLL_INTERVAL 30

#define PSU_PATH "/sys/class/power_supply"
#define DOZE_PATH "/sys/devices/system/device/suspend"
#define WAKELOCK_LOG "/data/local/tmp/battery_fix_wakelocks.log"

#define BATT_LEVEL_WARN 20
#define BATT_LEVEL_CRITICAL 10

static volatile sig_atomic_t running = 1;

typedef struct {
    int capacity;
    int health;
    int status;
    int temperature;
    int voltage;
    int current_now;
    int charge_full;
    int charge_counter;
    char health_str[32];
    char status_str[32];
} battery_state_t;

typedef struct {
    int doze_enabled;
    int motion_detect;
    int idle_timeout;
    int light_doze_timeout;
    int deep_doze_timeout;
} doze_config_t;

static void log_msg(const char *msg) {
    FILE *f;
    time_t now;
    struct tm *t;
    char buf[512];

    now = time(NULL);
    t = localtime(&now);
    snprintf(buf, sizeof(buf), "[%04d-%02d-%02d %02d:%02d:%02d] %s\n",
        t->tm_year + 1900, t->tm_mon + 1, t->tm_mday,
        t->tm_hour, t->tm_min, t->tm_sec, msg);

    f = fopen(LOG_FILE, "a");
    if (f) {
        fputs(buf, f);
        fclose(f);
    }
    __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "%s", msg);
}

static void log_wakelock(const char *name, const char *action) {
    FILE *f;
    time_t now;
    struct tm *t;
    char buf[256];

    now = time(NULL);
    t = localtime(&now);
    snprintf(buf, sizeof(buf), "[%04d-%02d-%02d %02d:%02d:%02d] %s: %s\n",
        t->tm_year + 1900, t->tm_mon + 1, t->tm_mday,
        t->tm_hour, t->tm_min, t->tm_sec, name, action);

    f = fopen(WAKELOCK_LOG, "a");
    if (f) {
        fputs(buf, f);
        fclose(f);
    }
}

static void handle_signal(int sig) {
    if (sig == SIGTERM || sig == SIGINT) {
        running = 0;
    }
}

static int read_sysfs_int(const char *path) {
    FILE *f;
    int val = -1;

    f = fopen(path, "r");
    if (f) {
        if (fscanf(f, "%d", &val) != 1) {
            val = -1;
        }
        fclose(f);
    }
    return val;
}

static int write_sysfs(const char *path, const char *value) {
    FILE *f;

    f = fopen(path, "w");
    if (f) {
        fputs(value, f);
        fclose(f);
        return 0;
    }
    return -1;
}

static int read_sysfs_str(const char *path, char *buf, size_t len) {
    FILE *f;

    f = fopen(path, "r");
    if (f) {
        if (fgets(buf, len, f)) {
            buf[strcspn(buf, "\n")] = '\0';
            fclose(f);
            return 0;
        }
        fclose(f);
    }
    return -1;
}

static int detect_battery_path(char *path, size_t len) {
    const char *candidates[] = {
        "battery",
        "Battery",
        "bms",
        NULL
    };
    char full_path[256];
    int i;

    for (i = 0; candidates[i]; i++) {
        snprintf(full_path, sizeof(full_path), "%s/%s/capacity", PSU_PATH, candidates[i]);
        if (access(full_path, R_OK) == 0) {
            snprintf(path, len, "%s/%s", PSU_PATH, candidates[i]);
            return 0;
        }
    }
    return -1;
}

static int read_battery_state(const char *psu_path, battery_state_t *state) {
    char path[256];
    char buf[64];

    memset(state, 0, sizeof(*state));

    snprintf(path, sizeof(path), "%s/capacity", psu_path);
    state->capacity = read_sysfs_int(path);

    snprintf(path, sizeof(path), "%s/health", psu_path);
    if (read_sysfs_str(path, buf, sizeof(buf)) == 0) {
        strncpy(state->health_str, buf, sizeof(state->health_str) - 1);
        if (strstr(buf, "Good")) state->health = 2;
        else if (strstr(buf, "Overheat")) state->health = 3;
        else if (strstr(buf, "Dead")) state->health = 4;
        else if (strstr(buf, "Over voltage")) state->health = 5;
        else state->health = 1;
    }

    snprintf(path, sizeof(path), "%s/status", psu_path);
    if (read_sysfs_str(path, buf, sizeof(buf)) == 0) {
        strncpy(state->status_str, buf, sizeof(state->status_str) - 1);
        if (strstr(buf, "Charging")) state->status = 2;
        else if (strstr(buf, "Discharging")) state->status = 3;
        else if (strstr(buf, "Full")) state->status = 5;
        else if (strstr(buf, "Not charging")) state->status = 4;
        else state->status = 1;
    }

    snprintf(path, sizeof(path), "%s/temp", psu_path);
    state->temperature = read_sysfs_int(path);

    snprintf(path, sizeof(path), "%s/voltage_now", psu_path);
    state->voltage = read_sysfs_int(path);

    snprintf(path, sizeof(path), "%s/current_now", psu_path);
    state->current_now = read_sysfs_int(path);

    snprintf(path, sizeof(path), "%s/charge_full", psu_path);
    state->charge_full = read_sysfs_int(path);

    snprintf(path, sizeof(path), "%s/charge_counter", psu_path);
    state->charge_counter = read_sysfs_int(path);

    return 0;
}

static void apply_power_saving(int level) {
    char msg[256];

    if (level <= BATT_LEVEL_CRITICAL) {
        log_msg("CRITICAL battery — aggressive power saving");

        write_sysfs("/proc/sys/vm/dirty_writeback_centisecs", "3000");
        write_sysfs("/proc/sys/vm/dirty_expire_centisecs", "3000");
        write_sysfs("/proc/sys/vm/dirty_background_ratio", "5");
        write_sysfs("/proc/sys/vm/dirty_ratio", "10");

        write_sysfs("/sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq", "1200000");
        write_sysfs("/sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq", "1500000");

        write_sysfs("/sys/class/devfreq/soc:qcom,cpubw/governor", "bw_hwmon");
        write_sysfs("/sys/class/devfreq/soc:qcom,cpu-llcc-ddr-bw/governor", "bw_hwmon");

        write_sysfs("/sys/class/leds/lcd-backlight/brightness", "50");

        system("cmd battery set adaptive 1 >/dev/null 2>&1");
        system("cmd power set-supersaver 1 >/dev/null 2>&1");

        log_msg("Applied critical power saving");
    } else if (level <= BATT_LEVEL_WARN) {
        log_msg("LOW battery — moderate power saving");

        write_sysfs("/proc/sys/vm/dirty_writeback_centisecs", "5000");
        write_sysfs("/proc/sys/vm/dirty_expire_centisecs", "5000");
        write_sysfs("/proc/sys/vm/dirty_background_ratio", "10");
        write_sysfs("/proc/sys/vm/dirty_ratio", "20");

        write_sysfs("/sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq", "1600000");
        write_sysfs("/sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq", "1800000");

        system("cmd battery set adaptive 1 >/dev/null 2>&1");

        log_msg("Applied moderate power saving");
    } else {
        snprintf(msg, sizeof(msg), "Battery OK (%d%%) — defaults restored", level);
        log_msg(msg);

        write_sysfs("/proc/sys/vm/dirty_writeback_centisecs", "500");
        write_sysfs("/proc/sys/vm/dirty_expire_centisecs", "3000");
        write_sysfs("/proc/sys/vm/dirty_background_ratio", "5");
        write_sysfs("/proc/sys/vm/dirty_ratio", "20");

        write_sysfs("/sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq", "2000000");
        write_sysfs("/sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq", "2000000");
    }
}

static void configure_doze(void) {
    log_msg("Configuring doze parameters");

    write_sysfs("/sys/devices/system/device/suspend/suspend_mode", "0");

    write_sysfs("/sys/module/lpm_levels/parameters/lpm_prediction", "Y");
    write_sysfs("/sys/module/lpm_levels/parameters/lpm_ipi_suspend", "Y");
    write_sysfs("/sys/module/lpm_levels/parameters/lpm_system_suspend_config", "Y");

    write_sysfs("/sys/power/cpuidle/s2idle/enable", "1");
}

static void optimize_wakelocks(void) {
    FILE *p;
    char buf[512];
    char wakelock_name[256];
    int count = 0;

    p = popen("cat /proc/wakelocks 2>/dev/null || dumpsys power | grep -i 'Wake Locks' -A 1000", "r");
    if (!p) return;

    while (fgets(buf, sizeof(buf), p)) {
        if (sscanf(buf, "%*d %s %*d %*d %*d %*d", wakelock_name) == 1) {
            count++;
            if (count > 50) {
                char msg[256];
                snprintf(msg, sizeof(msg), "Too many wakelocks (%d), logging top offenders", count);
                log_wakelock(wakelock_name, "active");
            }
        }
    }
    pclose(p);

    if (count > 30) {
        log_msg("High wakelock count — releasing stale wakelocks");
        system("cmd power release-all-wakelocks >/dev/null 2>&1");
    }
}

static void log_battery_summary(const battery_state_t *state) {
    char msg[512];

    snprintf(msg, sizeof(msg),
        "Battery: %d%% | Health: %s | Status: %s | Temp: %d.%dC | V=%dmV I=%dmA",
        state->capacity,
        state->health_str[0] ? state->health_str : "N/A",
        state->status_str[0] ? state->status_str : "N/A",
        state->temperature / 10, state->temperature % 10,
        state->voltage / 1000, state->current_now / 1000);
    log_msg(msg);
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
    struct sigaction sa;
    battery_state_t state;
    char psu_path[256];
    int last_level = -1;
    int poll_count = 0;

    if (access(DISABLE_FLAG, F_OK) == 0) {
        return 0;
    }

    while (!is_boot_completed()) {
        sleep(2);
    }
    sleep(5);

    if (access(DISABLE_FLAG, F_OK) == 0) {
        return 0;
    }

    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = handle_signal;
    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGINT, &sa, NULL);

    if (detect_battery_path(psu_path, sizeof(psu_path)) < 0) {
        log_msg("ERROR: Cannot find battery power supply");
        return 1;
    }

    {
        char msg[256];
        snprintf(msg, sizeof(msg), "Battery Fix v1.0.0 daemon started (PSU: %s, polling %ds)",
            psu_path, POLL_INTERVAL);
        log_msg(msg);
    }

    configure_doze();

    while (running) {
        if (access(DISABLE_FLAG, F_OK) == 0) {
            log_msg("Disable flag found, daemon stopping");
            break;
        }

        if (read_battery_state(psu_path, &state) == 0) {
            log_battery_summary(&state);

            if (state.capacity != last_level) {
                apply_power_saving(state.capacity);
                last_level = state.capacity;
            }

            if (state.temperature > 450) {
                char msg[256];
                snprintf(msg, sizeof(msg), "WARNING: Battery temperature high (%d.%dC)",
                    state.temperature / 10, state.temperature % 10);
                log_msg(msg);
            }
        }

        poll_count++;
        if (poll_count % 10 == 0) {
            optimize_wakelocks();
        }

        sleep(POLL_INTERVAL);
    }

    log_msg("Battery Fix daemon stopped");
    return 0;
}
