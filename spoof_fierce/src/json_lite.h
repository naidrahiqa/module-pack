#ifndef JSON_LITE_H
#define JSON_LITE_H

typedef struct {
    const char *data;
    size_t len;
} json_str_t;

typedef struct {
    const char *key;
    json_str_t val;
} json_kv_t;

int json_validate(const char *json);
const char *json_find_value(const char *json, const char *key, json_str_t *out);
int json_extract_int(const char *json, const char *key, int *out);
int json_extract_string(const char *json, const char *key, char *out, size_t outsz);
int json_extract_array(const char *json, const char *key, char *out, size_t outsz);
int json_add_to_array(const char *json, const char *key, const char *pkg, char *out, size_t outsz);
int json_remove_from_array(const char *json, const char *key, const char *pkg, char *out, size_t outsz);
int json_array_contains(const char *json, const char *key, const char *pkg);

#endif
