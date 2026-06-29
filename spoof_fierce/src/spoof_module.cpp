/* Spoof Fierce v1.0.0 — Universal Zygisk device spoofer
 * Auto-detects device, reads JSON config, spoofs Build.* fields
 * and system properties per-game for FPS unlock */

#include <jni.h>
#include <string>
#include <zygisk.hpp>
#include <fstream>
#include <unordered_map>
#include <unordered_set>
#include <vector>
#include <mutex>
#include <dlfcn.h>
#include <sys/mman.h>
#include <unistd.h>
#include <android/log.h>
#include <sys/stat.h>
#include <cstring>
#include <cstdlib>
#include <cerrno>
#include <fcntl.h>
#include <sys/system_properties.h>

#define LOG_TAG "SpoofFierce"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

static const char* CONFIG_PATH = "/data/adb/modules/spoof_fierce/SpoofFierce.json";

// ============================
// Device profile from JSON
// ============================
struct DeviceProfile {
    std::string brand;
    std::string manufacturer;
    std::string model;
    std::string device;
    std::string product;
    std::string fingerprint;
    std::string board;
    std::string hardware;
    std::string marketname;
    std::string android_version;
    int sdk_int = 0;
    int fps = 120;
};

// ============================
// Simple JSON parser (no deps)
// ============================
static std::string json_get_string(const std::string& json, const std::string& key) {
    std::string search = "\"" + key + "\"";
    auto pos = json.find(search);
    if (pos == std::string::npos) return "";
    pos = json.find(':', pos + search.size());
    if (pos == std::string::npos) return "";
    pos++;
    while (pos < json.size() && json[pos] == ' ') pos++;
    if (pos >= json.size()) return "";
    if (json[pos] == '"') {
        pos++;
        auto end = json.find('"', pos);
        if (end == std::string::npos) return "";
        return json.substr(pos, end - pos);
    }
    auto end = json.find_first_of(",}", pos);
    if (end == std::string::npos) return json.substr(pos);
    return json.substr(pos, end - pos);
}

static int json_get_int(const std::string& json, const std::string& key) {
    std::string val = json_get_string(json, key);
    if (val.empty()) return 0;
    return atoi(val.c_str());
}

// ============================
// Global state
// ============================
static DeviceProfile g_device;
static std::unordered_set<std::string> g_packages;
static std::mutex g_mutex;
static time_t g_last_mtime = 0;

// JNI field IDs (cached)
static jclass g_build_class = nullptr;
static jclass g_version_class = nullptr;

// ============================
// Config loader
// ============================
static void load_config() {
    struct stat st;
    if (stat(CONFIG_PATH, &st) != 0) return;
    if (st.st_mtime == g_last_mtime) return;

    std::ifstream file(CONFIG_PATH);
    if (!file.is_open()) return;
    std::string json((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
    file.close();

    // Parse device profile
    DeviceProfile dev;
    dev.brand = json_get_string(json, "brand");
    dev.manufacturer = json_get_string(json, "manufacturer");
    dev.model = json_get_string(json, "model");
    dev.device = json_get_string(json, "device");
    dev.product = json_get_string(json, "product");
    if (dev.product.empty()) dev.product = dev.brand;
    dev.fingerprint = json_get_string(json, "fingerprint");
    dev.board = json_get_string(json, "board");
    dev.hardware = json_get_string(json, "hardware");
    dev.marketname = json_get_string(json, "marketname");
    dev.android_version = json_get_string(json, "android_version");
    dev.sdk_int = json_get_int(json, "sdk_int");
    dev.fps = json_get_int(json, "fps");
    if (dev.fps == 0) dev.fps = 120;

    // Parse package list
    std::unordered_set<std::string> pkgs;
    auto pkg_pos = json.find("\"packages\"");
    if (pkg_pos != std::string::npos) {
        auto bracket = json.find('[', pkg_pos);
        if (bracket != std::string::npos) {
            auto close = json.find(']', bracket);
            if (close != std::string::npos) {
                std::string arr = json.substr(bracket + 1, close - bracket - 1);
                size_t start = 0;
                while (start < arr.size()) {
                    auto q1 = arr.find('"', start);
                    if (q1 == std::string::npos) break;
                    auto q2 = arr.find('"', q1 + 1);
                    if (q2 == std::string::npos) break;
                    std::string pkg = arr.substr(q1 + 1, q2 - q1 - 1);
                    // Strip tags like :cow
                    auto colon = pkg.find(':');
                    if (colon != std::string::npos) pkg = pkg.substr(0, colon);
                    if (!pkg.empty()) pkgs.insert(pkg);
                    start = q2 + 1;
                }
            }
        }
    }

    {
        std::lock_guard<std::mutex> lock(g_mutex);
        g_device = dev;
        g_packages = pkgs;
    }
    g_last_mtime = st.st_mtime;

    LOGI("Config loaded: model=%s brand=%s fps=%d packages=%zu",
         dev.model.c_str(), dev.brand.c_str(), dev.fps, pkgs.size());
}

// ============================
// Auto-detect real device
// ============================
static DeviceProfile detect_device() {
    DeviceProfile real;
    char buf[PROP_VALUE_MAX];

    __system_property_get("ro.product.brand", buf);
    real.brand = buf;
    __system_property_get("ro.product.manufacturer", buf);
    real.manufacturer = buf;
    __system_property_get("ro.product.model", buf);
    real.model = buf;
    __system_property_get("ro.product.device", buf);
    real.device = buf;
    __system_property_get("ro.product.name", buf);
    real.product = buf;
    __system_property_get("ro.build.fingerprint", buf);
    real.fingerprint = buf;
    __system_property_get("ro.product.board", buf);
    real.board = buf;
    __system_property_get("ro.hardware", buf);
    real.hardware = buf;
    __system_property_get("ro.build.version.release", buf);
    real.android_version = buf;

    // SDK_INT from __system_property_get
    real.sdk_int = android_get_device_api_level();

    return real;
}

// ============================
// Spoof Build.* via JNI
// ============================
static void spoof_build_fields(JNIEnv* env, const DeviceProfile& dev) {
    if (!g_build_class) return;

    auto set_str = [&](jclass cls, const char* name, const std::string& val) {
        if (val.empty()) return;
        jfieldID fid = env->GetStaticFieldID(cls, name, "Ljava/lang/String;");
        if (env->ExceptionCheck()) { env->ExceptionClear(); return; }
        jstring js = env->NewStringUTF(val.c_str());
        env->SetStaticObjectField(cls, fid, js);
        env->DeleteLocalRef(js);
        if (env->ExceptionCheck()) env->ExceptionClear();
    };

    set_str(g_build_class, "MODEL", dev.model);
    set_str(g_build_class, "BRAND", dev.brand);
    set_str(g_build_class, "MANUFACTURER", dev.manufacturer);
    set_str(g_build_class, "DEVICE", dev.device);
    set_str(g_build_class, "PRODUCT", dev.product);
    set_str(g_build_class, "FINGERPRINT", dev.fingerprint);
    set_str(g_build_class, "BOARD", dev.board);
    set_str(g_build_class, "HARDWARE", dev.hardware);
    set_str(g_build_class, "DISPLAY", dev.model);
    set_str(g_build_class, "HOST", "build/release-keys");

    if (g_version_class) {
        if (!dev.android_version.empty())
            set_str(g_version_class, "RELEASE", dev.android_version);
        if (dev.sdk_int > 0) {
            jfieldID sdk_fid = env->GetStaticFieldID(g_version_class, "SDK_INT", "I");
            if (sdk_fid) {
                env->SetStaticIntField(g_version_class, sdk_fid, dev.sdk_int);
                if (env->ExceptionCheck()) env->ExceptionClear();
            }
        }
    }

    LOGI("Build fields spoofed: %s %s", dev.model.c_str(), dev.brand.c_str());
}

// ============================
// COW prop spoof (per-process)
// ============================
static std::vector<std::pair<uintptr_t, uintptr_t>> g_cow_ranges;

static bool ensure_cow(const void* addr) {
    uintptr_t t = (uintptr_t)addr;
    for (auto& r : g_cow_ranges)
        if (t >= r.first && t < r.second) return true;

    FILE* f = fopen("/proc/self/maps", "r");
    if (!f) return false;
    char line[512];
    bool ok = false;
    while (fgets(line, sizeof(line), f)) {
        uintptr_t s, e;
        unsigned long long off;
        char perms[8], path[256];
        path[0] = 0;
        if (sscanf(line, "%lx-%lx %7s %llx %*x:%*x %*u %255[^\n]", &s, &e, perms, &off, path) < 4)
            continue;
        if (t < s || t >= e) continue;
        char* p = path;
        while (*p == ' ') p++;
        if (strncmp(p, "/dev/__properties__", 19) != 0) break;
        int fd = open(p, O_RDONLY);
        if (fd >= 0) {
            void* r = mmap((void*)s, (size_t)(e - s), PROT_READ | PROT_WRITE,
                           MAP_PRIVATE | MAP_FIXED, fd, (off_t)off);
            close(fd);
            if (r != MAP_FAILED) { g_cow_ranges.push_back({s, e}); ok = true; }
        }
        break;
    }
    fclose(f);
    return ok;
}

static void spoof_prop(const char* name, const char* val) {
    const prop_info* pi = __system_property_find(name);
    if (!pi) return;
    size_t len = strlen(val);
    if (len >= PROP_VALUE_MAX) return;
    if (!ensure_cow(pi)) return;

    volatile uint32_t* serial = (volatile uint32_t*)pi;
    char* value = (char*)pi + sizeof(uint32_t);
    uint32_t old = *serial;
    *serial = old | 1;
    __sync_synchronize();
    memcpy(value, val, len);
    value[len] = '\0';
    __sync_synchronize();
    *serial = ((uint32_t)len << 24) | (((old & 0x00FFFFFFu) + 2) & 0x00FFFFFFu);
    __sync_synchronize();
}

static void spoof_props(const DeviceProfile& dev) {
    spoof_prop("ro.product.model", dev.model.c_str());
    spoof_prop("ro.product.brand", dev.brand.c_str());
    spoof_prop("ro.product.manufacturer", dev.manufacturer.c_str());
    spoof_prop("ro.product.device", dev.device.c_str());
    spoof_prop("ro.product.name", dev.product.c_str());
    spoof_prop("ro.product.board", dev.board.c_str());
    spoof_prop("ro.product.marketname", dev.marketname.c_str());
    spoof_prop("ro.build.fingerprint", dev.fingerprint.c_str());

    // Hardware + platform spoof (safe in Zygisk — display already initialized)
    // HOK reads ro.hardware / ro.board.platform to whitelist FPS
    if (!dev.hardware.empty())
        spoof_prop("ro.hardware", dev.hardware.c_str());
    if (!dev.board.empty())
        spoof_prop("ro.board.platform", dev.board.c_str());

    // NEVER spoof ro.product.vendor.* / ro.product.odm.* / ro.product.system.*
    // Vendor props control radio/RIL — changing them = signal loss

    // FPS override + master switch
    char fps_str[16];
    snprintf(fps_str, sizeof(fps_str), "%d", dev.fps);
    spoof_prop("ro.surface_flinger.game_default_frame_rate_override", fps_str);
    spoof_prop("ro.surface_flinger.enable_frame_rate_override", "true");

    LOGI("Props spoofed via COW");
}

// ============================
// Zygisk module
// ============================
class SpoofFierceModule : public zygisk::ModuleBase {
public:
    void onLoad(zygisk::Api* api, JNIEnv* env) override {
        m_api = api;
        m_env = env;
        load_config();
        ensure_build_class();
    }

    void preAppSpecialize(zygisk::AppSpecializeArgs* args) override {
        if (!args->nice_name) {
            m_api->setOption(zygisk::Option::DLCLOSE_MODULE_LIBRARY);
            return;
        }

        const char* pkg_name = m_env->GetStringUTFChars(args->nice_name, nullptr);
        if (!pkg_name) {
            m_api->setOption(zygisk::Option::DLCLOSE_MODULE_LIBRARY);
            return;
        }

        std::string package(pkg_name);
        m_env->ReleaseStringUTFChars(args->nice_name, pkg_name);

        // Strip :process suffix
        auto colon = package.find(':');
        if (colon != std::string::npos) package = package.substr(0, colon);

        // Reload config if changed
        load_config();

        bool found = false;
        {
            std::lock_guard<std::mutex> lock(g_mutex);
            found = g_packages.count(package) > 0;
        }

        if (!found) {
            m_api->setOption(zygisk::Option::DLCLOSE_MODULE_LIBRARY);
            return;
        }

        LOGI("Spoofing: %s", package.c_str());

        // Spoof Build.* fields
        {
            std::lock_guard<std::mutex> lock(g_mutex);
            spoof_build_fields(m_env, g_device);
            m_device = g_device;
        }

        // COW prop spoof
        spoof_props(m_device);

        m_api->setOption(zygisk::Option::DLCLOSE_MODULE_LIBRARY);
    }

private:
    zygisk::Api* m_api = nullptr;
    JNIEnv* m_env = nullptr;
    DeviceProfile m_device;

    void ensure_build_class() {
        if (g_build_class) return;
        jclass local = m_env->FindClass("android/os/Build");
        if (!local) { m_env->ExceptionClear(); return; }
        g_build_class = (jclass)m_env->NewGlobalRef(local);
        m_env->DeleteLocalRef(local);

        jclass local_ver = m_env->FindClass("android/os/Build$VERSION");
        if (local_ver) {
            g_version_class = (jclass)m_env->NewGlobalRef(local_ver);
            m_env->DeleteLocalRef(local_ver);
        }
    }
};

REGISTER_ZYGISK_MODULE(SpoofFierceModule)
