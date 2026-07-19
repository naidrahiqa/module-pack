#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "json_lite.h"

int json_validate(const char *json) {
    int depth = 0;
    int in_string = 0;
    int escaped = 0;
    const char *p;

    if (!json || !*json) return 0;

    for (p = json; *p; p++) {
        if (escaped) { escaped = 0; continue; }
        if (*p == '\\' && in_string) { escaped = 1; continue; }
        if (*p == '"') { in_string = !in_string; continue; }
        if (in_string) continue;
        if (*p == '{' || *p == '[') depth++;
        if (*p == '}' || *p == ']') depth--;
        if (depth < 0) return 0;
    }
    return depth == 0 && !in_string;
}

static const char *skip_ws(const char *p) {
    while (*p && isspace((unsigned char)*p)) p++;
    return p;
}

static const char *find_key(const char *json, const char *key) {
    char needle[256];
    const char *found;
    size_t klen = strlen(key);

    snprintf(needle, sizeof(needle), "\"%s\"", key);
    found = strstr(json, needle);
    if (!found) return NULL;
    found += klen + 2;
    found = skip_ws(found);
    if (*found != ':') return NULL;
    return skip_ws(found + 1);
}

static const char *skip_value(const char *p) {
    int depth = 0;
    int in_str = 0;
    int esc = 0;

    if (*p == '"') {
        p++;
        while (*p && (in_str || *p != '"')) {
            if (esc) { esc = 0; }
            else if (*p == '\\') { esc = 1; }
            else if (*p == '"') { in_str = !in_str; }
            p++;
        }
        return p + 1;
    }
    if (*p == '{' || *p == '[') {
        char open = *p;
        char close = (open == '{') ? '}' : ']';
        p++; depth = 1;
        while (*p && depth > 0) {
            if (*p == '"') { p++; while (*p && *p != '"') { if (*p == '\\') p++; p++; } }
            if (*p == open) depth++;
            if (*p == close) depth--;
            p++;
        }
        return p;
    }
    while (*p && *p != ',' && *p != '}' && *p != ']') p++;
    return p;
}

int json_extract_string(const char *json, const char *key, char *out, size_t outsz) {
    const char *val = find_key(json, key);
    const char *end;
    size_t len;

    if (!val || *val != '"') return -1;
    val++;
    end = val;
    while (*end && *end != '"') {
        if (*end == '\\') end++;
        end++;
    }
    len = end - val;
    if (len >= outsz) len = outsz - 1;
    memcpy(out, val, len);
    out[len] = '\0';
    return 0;
}

int json_extract_int(const char *json, const char *key, int *out) {
    const char *val = find_key(json, key);
    if (!val) return -1;
    *out = atoi(val);
    return 0;
}

int json_extract_array(const char *json, const char *key, char *out, size_t outsz) {
    const char *val = find_key(json, key);
    const char *end;
    size_t len;

    if (!val || *val != '[') return -1;
    end = val;
    {
        int depth = 1;
        int in_str = 0;
        int esc = 0;
        end++;
        while (*end && depth > 0) {
            if (esc) { esc = 0; }
            else if (*end == '\\' && in_str) { esc = 1; }
            else if (*end == '"') { in_str = !in_str; }
            else if (!in_str) {
                if (*end == '[') depth++;
                if (*end == ']') depth--;
            }
            end++;
        }
    }
    len = end - val;
    if (len >= outsz) len = outsz - 1;
    memcpy(out, val, len);
    out[len] = '\0';
    return 0;
}

int json_array_contains(const char *json, const char *key, const char *pkg) {
    char arr[8192];
    char needle[256];

    if (json_extract_array(json, key, arr, sizeof(arr)) != 0) return 0;
    snprintf(needle, sizeof(needle), "\"%s\"", pkg);
    return strstr(arr, needle) != NULL;
}

int json_add_to_array(const char *json, const char *key, const char *pkg, char *out, size_t outsz) {
    char arr[8192];
    char new_entry[256];
    const char *arr_start;
    const char *arr_end;

    if (json_extract_array(json, key, arr, sizeof(arr)) != 0) return -1;

    if (json_array_contains(json, key, pkg)) {
        snprintf(out, outsz, "%s", json);
        return 0;
    }

    snprintf(new_entry, sizeof(new_entry), ", \"%s\"", pkg);
    arr_start = strstr(json, arr);
    if (!arr_start) return -1;
    arr_end = arr_start + strlen(arr);

    {
        size_t before = arr_start - json + strlen(arr) - 1;
        size_t addlen = strlen(new_entry);
        size_t afterlen = strlen(arr_end);
        if (before + addlen + afterlen >= outsz) return -1;
        memcpy(out, json, before);
        memcpy(out + before, new_entry, addlen);
        memcpy(out + before + addlen, arr_end, afterlen + 1);
    }
    return 0;
}

int json_remove_from_array(const char *json, const char *key, const char *pkg, char *out, size_t outsz) {
    char arr[8192];
    char needle[256];
    char *match;
    const char *arr_start;
    size_t arr_len;

    if (json_extract_array(json, key, arr, sizeof(arr)) != 0) return -1;

    snprintf(needle, sizeof(needle), "\"%s\"", pkg);
    match = strstr(arr, needle);
    if (!match) {
        snprintf(out, outsz, "%s", json);
        return 0;
    }

    {
        char *before = match;
        char *after = match + strlen(needle);

        while (before > arr && *(before - 1) == ' ') before--;
        if (before > arr && *(before - 1) == ',') {
            before--;
            while (before > arr && *(before - 1) == ' ') before--;
        } else {
            while (*after == ' ' || *after == ',') after++;
        }

        arr_start = strstr(json, arr);
        if (!arr_start) return -1;
        arr_len = strlen(arr);

        {
            size_t prefix = before - arr;
            size_t suffix_len = arr_len - (after - arr);
            size_t pre = arr_start - json + prefix;
            size_t post_len = strlen(arr_start + arr_len);
            if (pre + suffix_len + post_len >= outsz) return -1;
            memcpy(out, json, pre);
            memcpy(out + pre, after, suffix_len);
            memcpy(out + pre + suffix_len, arr_start + arr_len, post_len + 1);
        }
    }
    return 0;
}
