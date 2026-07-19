#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <sys/stat.h>
#include <android/log.h>
#include "json_lite.h"

#define LOG_TAG "SpoofAPI"
#define CONFIG_PATH "/data/adb/modules/spoof_fierce/SpoofFierce.json"
#define WEBROOT "/data/adb/modules/spoof_fierce/webroot"
#define LOG_FILE "/data/local/tmp/spoof_fierce.log"
#define RESETPROP "/data/adb/ksu/bin/resetprop"
#define ACTIVE_FLAG "/data/local/tmp/spoof_fierce_active"

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
    if (f) { fputs(buf, f); fclose(f); }
    __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "%s", msg);
}

static char *read_file(const char *path) {
    FILE *f;
    long sz;
    char *buf;

    f = fopen(path, "r");
    if (!f) return NULL;
    fseek(f, 0, SEEK_END);
    sz = ftell(f);
    fseek(f, 0, SEEK_SET);
    buf = malloc(sz + 1);
    if (buf) {
        fread(buf, 1, sz, f);
        buf[sz] = '\0';
    }
    fclose(f);
    return buf;
}

static int write_file(const char *path, const char *data) {
    FILE *f = fopen(path, "w");
    if (!f) return -1;
    fputs(data, f);
    fclose(f);
    return 0;
}

static void rp_set(const char *prop, const char *val) {
    char cmd[512];
    snprintf(cmd, sizeof(cmd), "%s %s \"%s\" 2>/dev/null", RESETPROP, prop, val);
    system(cmd);
}

static void rp_delete(const char *prop) {
    char cmd[512];
    snprintf(cmd, sizeof(cmd), "%s --delete %s 2>/dev/null", RESETPROP, prop);
    system(cmd);
}

static void do_status(void) {
    char *raw;
    char model[128], brand[128], mfr[128], dev[128], board[128], hw[128];
    char mkt[128], fp[256], android[32], pkgs[4096], out[8192];
    char real[4096] = "{}";
    int fps;
    FILE *f;

    raw = read_file(CONFIG_PATH);
    if (!raw) { printf("{}\n"); return; }

    json_extract_string(raw, "model", model, sizeof(model));
    json_extract_string(raw, "brand", brand, sizeof(brand));
    json_extract_string(raw, "manufacturer", mfr, sizeof(mfr));
    json_extract_string(raw, "device", dev, sizeof(dev));
    json_extract_string(raw, "board", board, sizeof(board));
    json_extract_string(raw, "hardware", hw, sizeof(hw));
    json_extract_string(raw, "marketname", mkt, sizeof(mkt));
    json_extract_string(raw, "fingerprint", fp, sizeof(fp));
    json_extract_string(raw, "android_version", android, sizeof(android));
    json_extract_int(raw, "fps", &fps);
    json_extract_array(raw, "packages", pkgs, sizeof(pkgs));

    f = fopen(WEBROOT "/real_device.json", "r");
    if (f) { fread(real, 1, sizeof(real) - 1, f); fclose(f); }

    snprintf(out, sizeof(out),
        "{\"active\":%s,\"model\":\"%s\",\"brand\":\"%s\",\"manufacturer\":\"%s\","
        "\"device\":\"%s\",\"board\":\"%s\",\"fps\":%d,\"marketname\":\"%s\","
        "\"hardware\":\"%s\",\"fingerprint\":\"%s\",\"android\":\"%s\","
        "\"packages\":%s,\"real\":%s}",
        access(ACTIVE_FLAG, F_OK) == 0 ? "true" : "false",
        model, brand, mfr, dev, board, fps, mkt, hw, fp, android, pkgs, real);

    printf("%s\n", out);

    {
        char path[256];
        snprintf(path, sizeof(path), "%s/status.json", WEBROOT);
        write_file(path, out);
        chmod(path, 0644);
    }
    free(raw);
}

static void do_scan(void) {
    FILE *p;
    char buf[256];
    char path[256];
    int first = 1;

    snprintf(path, sizeof(path), "%s/apps.json", WEBROOT);
    FILE *out = fopen(path, "w");
    if (!out) return;
    fputs("[\n", out);

    p = popen("pm list packages -3 2>/dev/null", "r");
    if (p) {
        while (fgets(buf, sizeof(buf), p)) {
            char *nl = strchr(buf, '\n');
            if (nl) *nl = '\0';
            char *pkg = strchr(buf, ':');
            if (pkg) pkg++; else pkg = buf;
            if (*pkg == '\0') continue;

            char label[256] = {0};

            /* Format package name: remove prefixes, capitalize words */
            const char *prefixes[] = {"com.", "org.", "net.", "io.", "app.", "android.", NULL};
            const char *src = pkg;
            int i;
            for (i = 0; prefixes[i]; i++) {
                if (strncmp(src, prefixes[i], strlen(prefixes[i])) == 0) {
                    src += strlen(prefixes[i]);
                    break;
                }
            }
            
            /* Capitalize first letter of each word, replace dots with spaces */
            int sl = 0;
            int new_word = 1;
            const char *s = src;
            while (*s && sl < 255) {
                if (*s == '.') {
                    label[sl++] = ' ';
                    new_word = 1;
                } else if (new_word) {
                    label[sl++] = (*s >= 'a' && *s <= 'z') ? *s - 32 : *s;
                    new_word = 0;
                } else {
                    label[sl++] = *s;
                }
                s++;
            }
            label[sl] = '\0';
            
            if (label[0] == '\0') {
                const char *last = strrchr(pkg, '.');
                strncpy(label, last ? last + 1 : pkg, sizeof(label) - 1);
            }

            if (!first) fprintf(out, ",\n");
            fprintf(out, "  {\"pkg\":\"%s\",\"name\":\"%s\"}", pkg, label);
            first = 0;
        }
        pclose(p);
    }
    fputs("\n]\n", out);
    fclose(out);
    chmod(path, 0644);
    log_msg("Scanned apps");
}

static void do_add(const char *pkg) {
    char *raw;
    char out[16384];

    if (!pkg || !*pkg) { printf("ERROR\n"); return; }
    raw = read_file(CONFIG_PATH);
    if (!raw) { printf("ERROR\n"); return; }

    if (json_array_contains(raw, "packages", pkg)) {
        printf("EXISTS\n");
        free(raw);
        return;
    }

    if (json_add_to_array(raw, "packages", pkg, out, sizeof(out)) == 0) {
        write_file(CONFIG_PATH, out);
        log_msg(pkg);
        {
            char msg[256];
            snprintf(msg, sizeof(msg), "Added: %s", pkg);
            log_msg(msg);
        }
        printf("OK\n");
    } else {
        printf("ERROR\n");
    }
    free(raw);
}

static void do_remove(const char *pkg) {
    char *raw;
    char out[16384];

    if (!pkg || !*pkg) { printf("ERROR\n"); return; }
    raw = read_file(CONFIG_PATH);
    if (!raw) { printf("ERROR\n"); return; }

    if (json_remove_from_array(raw, "packages", pkg, out, sizeof(out)) == 0) {
        write_file(CONFIG_PATH, out);
        {
            char msg[256];
            snprintf(msg, sizeof(msg), "Removed: %s", pkg);
            log_msg(msg);
        }
        printf("OK\n");
    } else {
        printf("ERROR\n");
    }
    free(raw);
}

static void do_apply(const char *pkg) {
    char *raw;
    char model[128], brand[128], mfr[128], dev[128], board[128], hw[128];
    char mkt[128], fp[256], android[32], build_id[128], build_num[128];
    char new_fp[512];
    int fps;

    raw = read_file(CONFIG_PATH);
    if (!raw) { printf("ERROR\n"); return; }

    json_extract_string(raw, "model", model, sizeof(model));
    json_extract_string(raw, "brand", brand, sizeof(brand));
    json_extract_string(raw, "manufacturer", mfr, sizeof(mfr));
    json_extract_string(raw, "device", dev, sizeof(dev));
    json_extract_string(raw, "board", board, sizeof(board));
    json_extract_string(raw, "hardware", hw, sizeof(hw));
    json_extract_string(raw, "marketname", mkt, sizeof(mkt));
    json_extract_int(raw, "fps", &fps);
    if (fps <= 0) fps = 120;

    {
        char cmd[256];
        FILE *p;
        p = popen("getprop ro.build.version.release", "r");
        if (p) { fgets(android, sizeof(android), p); pclose(p); }
        char *nl = strchr(android, '\n'); if (nl) *nl = '\0';

        p = popen("getprop ro.build.display.id", "r");
        if (p) { fgets(build_id, sizeof(build_id), p); pclose(p); }
        nl = strchr(build_id, '\n'); if (nl) *nl = '\0';
        char *sp = strchr(build_id, ' ');
        if (sp) *sp = '\0';

        p = popen("getprop ro.build.version.incremental", "r");
        if (p) { fgets(build_num, sizeof(build_num), p); pclose(p); }
        nl = strchr(build_num, '\n'); if (nl) *nl = '\0';
    }

    snprintf(new_fp, sizeof(new_fp), "%s/%s/%s:%s/%s/%s:user/release-keys",
        brand, dev, dev, android, build_id, build_num);

    rp_set("ro.product.model", model);
    rp_set("ro.product.brand", brand);
    rp_set("ro.product.manufacturer", mfr);
    rp_set("ro.product.device", dev);
    rp_set("ro.product.board", board);
    rp_set("ro.product.marketname", mkt);
    rp_set("ro.board.platform", board);
    if (hw[0]) rp_set("ro.hardware", hw);
    rp_set("ro.build.fingerprint", new_fp);
    {
        char fps_str[32];
        snprintf(fps_str, sizeof(fps_str), "%d", fps);
        rp_set("ro.surface_flinger.game_default_frame_rate_override", fps_str);
    }
    rp_set("ro.surface_flinger.enable_frame_rate_override", "true");
    rp_set("debug.graphics.game_default_frame_rate_disabled", "false");
    rp_set("debug.graphics.game_default_frame_rate.disabled", "false");
    rp_set("debug.sf.frame_rate_multiple_threshold", "0");

    {
        FILE *f = fopen(ACTIVE_FLAG, "w");
        if (f) { fputs("active", f); fclose(f); }
    }

    {
        char msg[256];
        snprintf(msg, sizeof(msg), "Applied spoof: %s", model);
        log_msg(msg);
    }
    printf("OK\n");
    free(raw);
}

static void do_set_device(const char *json_str) {
    if (!json_str || !*json_str) { printf("ERROR\n"); return; }

    if (!json_validate(json_str)) {
        log_msg("ERROR: set_device received invalid JSON");
        printf("ERROR\n");
        return;
    }

    write_file(CONFIG_PATH, json_str);
    log_msg("Config updated via set_device");
    printf("OK\n");
}

static void do_restore(void) {
    const char *props[] = {
        "ro.product.model", "ro.product.brand", "ro.product.manufacturer",
        "ro.product.device", "ro.product.board", "ro.product.marketname",
        "ro.hardware", "ro.board.platform", "ro.build.fingerprint",
        "ro.surface_flinger.game_default_frame_rate_override",
        "ro.surface_flinger.enable_frame_rate_override",
        "debug.graphics.game_default_frame_rate_disabled",
        "debug.graphics.game_default_frame_rate.disabled",
        "debug.sf.frame_rate_multiple_threshold",
        NULL
    };
    int i;
    for (i = 0; props[i]; i++) {
        rp_delete(props[i]);
    }
    unlink(ACTIVE_FLAG);
    log_msg("Restored all props");
    printf("OK\n");
}

static void do_log(void) {
    char buf[4096];
    FILE *f = fopen(LOG_FILE, "r");
    if (!f) { printf("No log\n"); return; }
    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    if (sz > 4000) fseek(f, sz - 4000, SEEK_SET);
    while (fgets(buf, sizeof(buf), f)) fputs(buf, stdout);
    fclose(f);
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("Usage: spoof_api <action> [arg]\n");
        return 1;
    }

    if (strcmp(argv[1], "status") == 0) do_status();
    else if (strcmp(argv[1], "scan") == 0) do_scan();
    else if (strcmp(argv[1], "add") == 0 && argc > 2) do_add(argv[2]);
    else if (strcmp(argv[1], "remove") == 0 && argc > 2) do_remove(argv[2]);
    else if (strcmp(argv[1], "apply") == 0 && argc > 2) do_apply(argv[2]);
    else if (strcmp(argv[1], "set_device") == 0 && argc > 2) do_set_device(argv[2]);
    else if (strcmp(argv[1], "restore") == 0) do_restore();
    else if (strcmp(argv[1], "log") == 0) do_log();
    else { printf("Unknown action: %s\n", argv[1]); return 1; }

    return 0;
}
