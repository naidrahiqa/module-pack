#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <errno.h>
#include <dirent.h>
#include <android/log.h>

#define LOG_TAG "NetworkFix"
#define LOG_FILE "/data/local/tmp/network_fix.log"
#define DISABLE_FLAG "/data/local/tmp/network_fix_disable"
#define APPLY_INTERVAL 60
#define DNS_SERVER_1 "8.8.8.8"
#define DNS_SERVER_2 "8.8.4.4"
#define DNS_CACHE_TTL 3600

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

static void write_proc(const char *path, const char *value) {
    FILE *f = fopen(path, "w");
    if (f) {
        fputs(value, f);
        fclose(f);
    }
}

static char *read_proc(const char *path, char *buf, size_t len) {
    FILE *f = fopen(path, "r");
    if (f) {
        if (fgets(buf, len, f)) {
            buf[strcspn(buf, "\n")] = '\0';
            fclose(f);
            return buf;
        }
        fclose(f);
    }
    buf[0] = '\0';
    return buf;
}

static void apply_tcp_opts(void) {
    /* TCP FastOpen: client + server (mode 3) */
    write_proc("/proc/sys/net/ipv4/tcp_fastopen", "3");
    log_msg("tcp_fastopen=3");

    /* SYN cookies */
    write_proc("/proc/sys/net/ipv4/tcp_syncookies", "1");
    log_msg("tcp_syncookies=1");

    /* TCP timestamps */
    write_proc("/proc/sys/net/ipv4/tcp_timestamps", "1");
    log_msg("tcp_timestamps=1");

    /* TCP SACK */
    write_proc("/proc/sys/net/ipv4/tcp_sack", "1");
    log_msg("tcp_sack=1");

    /* TCP window scaling */
    write_proc("/proc/sys/net/ipv4/tcp_window_scaling", "1");
    log_msg("tcp_window_scaling=1");

    /* TCP keepalive: 600s, 6 probes, 30s interval */
    write_proc("/proc/sys/net/ipv4/tcp_keepalive_time", "600");
    write_proc("/proc/sys/net/ipv4/tcp_keepalive_probes", "6");
    write_proc("/proc/sys/net/ipv4/tcp_keepalive_intvl", "30");
    log_msg("tcp_keepalive=600/6/30");

    /* TCP max SYN backlog */
    write_proc("/proc/sys/net/ipv4/tcp_max_syn_backlog", "4096");
    log_msg("tcp_max_syn_backlog=4096");

    /* TCP fin timeout */
    write_proc("/proc/sys/net/ipv4/tcp_fin_timeout", "30");
    log_msg("tcp_fin_timeout=30");

    /* TCP reuse */
    write_proc("/proc/sys/net/ipv4/tcp_tw_reuse", "1");
    log_msg("tcp_tw_reuse=1");

    /* TCP slow start after idle: disable */
    write_proc("/proc/sys/net/ipv4/tcp_slow_start_after_idle", "0");
    log_msg("tcp_slow_start_after_idle=0");

    /* Network device backlog */
    write_proc("/proc/sys/net/core/netdev_max_backlog", "5000");
    log_msg("netdev_max_backlog=5000");

    /* Socket buffer sizes: 256KB */
    write_proc("/proc/sys/net/core/rmem_max", "262144");
    write_proc("/proc/sys/net/core/wmem_max", "262144");
    write_proc("/proc/sys/net/core/rmem_default", "262144");
    write_proc("/proc/sys/net/core/wmem_default", "262144");
    log_msg("socket_buffers=262144");

    /* TCP mem: min pressure max (in pages, 1 page = 4KB) */
    write_proc("/proc/sys/net/ipv4/tcp_mem", "786432 1048576 1572864");
    log_msg("tcp_mem=786432/1048576/1572864");

    /* TCP rmem/wmem: min default max (bytes) */
    write_proc("/proc/sys/net/ipv4/tcp_rmem", "4096 262144 16777216");
    write_proc("/proc/sys/net/ipv4/tcp_wmem", "4096 262144 16777216");
    log_msg("tcp_rmem/wmem=4096/262144/16777216");

    /* ICMP rate limit */
    write_proc("/proc/sys/net/ipv4/icmp_echo_ignore_broadcasts", "1");
    log_msg("icmp_echo_ignore_broadcasts=1");

    /* IP early demux */
    write_proc("/proc/sys/net/ipv4/ip_early_demux", "1");
    log_msg("ip_early_demux=1");
}

static void apply_dns_cache(void) {
    char cmd[256];

    /* Set DNS servers via resetprop */
    snprintf(cmd, sizeof(cmd), "resetprop net.dns1 %s", DNS_SERVER_1);
    system(cmd);
    snprintf(cmd, sizeof(cmd), "resetprop net.dns2 %s", DNS_SERVER_2);
    system(cmd);

    /* Set DNS cache TTL */
    snprintf(cmd, sizeof(cmd), "resetprop net.dns.cache.expiry %d", DNS_CACHE_TTL);
    system(cmd);

    snprintf(cmd, sizeof(cmd), "DNS servers set: %s, %s (TTL=%d)",
        DNS_SERVER_1, DNS_SERVER_2, DNS_CACHE_TTL);
    log_msg(cmd);
}

static void log_network_stats(void) {
    FILE *f;
    char buf[512];
    char line[256];
    unsigned long rx_bytes = 0, tx_bytes = 0;
    unsigned long rx_packets = 0, tx_packets = 0;
    unsigned long rx_errors = 0, tx_errors = 0;
    int iface_count = 0;

    f = fopen("/proc/net/dev", "r");
    if (!f) return;

    /* Skip header lines */
    fgets(buf, sizeof(buf), f);
    fgets(buf, sizeof(buf), f);

    while (fgets(line, sizeof(line), f)) {
        char *colon = strchr(line, ':');
        if (!colon) continue;
        *colon = ' ';

        unsigned long rb, rp, re, tb, tp, te;
        if (sscanf(colon + 1, "%lu %lu %lu %*u %*u %*u %*u %*u %lu %lu %lu",
                   &rb, &rp, &re, &tb, &tp, &te) == 6) {
            rx_bytes += rb;
            rx_packets += rp;
            rx_errors += re;
            tx_bytes += tb;
            tx_packets += tp;
            tx_errors += te;
            iface_count++;
        }
    }
    fclose(f);

    snprintf(buf, sizeof(buf),
        "net_stats: %d ifaces, RX=%luB/%luP/%luE TX=%luB/%luP/%luE",
        iface_count, rx_bytes, rx_packets, rx_errors,
        tx_bytes, tx_packets, tx_errors);
    log_msg(buf);
}

static void check_connectivity(void) {
    int sock;
    struct sockaddr_in addr;

    sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        log_msg("connectivity_check: socket creation failed");
        return;
    }

    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(53);
    inet_pton(AF_INET, DNS_SERVER_1, &addr.sin_addr);

    /* Quick connect with 3s timeout */
    struct timeval tv;
    tv.tv_sec = 3;
    tv.tv_usec = 0;
    setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv));

    if (connect(sock, (struct sockaddr *)&addr, sizeof(addr)) == 0) {
        log_msg("connectivity_check: OK (DNS reachable)");
    } else {
        log_msg("connectivity_check: FAILED (DNS unreachable)");
    }

    close(sock);
}

static int is_iface_up(const char *iface) {
    char path[128];
    char val[16];
    snprintf(path, sizeof(path), "/sys/class/net/%s/operstate", iface);
    if (read_proc(path, val, sizeof(val))) {
        return strcmp(val, "up") == 0;
    }
    return 0;
}

static void apply_iface_opts(const char *iface) {
    char path[256];
    char msg[256];

    /* Increase txqueuelen for better throughput */
    snprintf(path, sizeof(path), "/sys/class/net/%s/tx_queue_len", iface);
    write_proc(path, "1000");
    snprintf(msg, sizeof(msg), "%s: tx_queue_len=1000", iface);
    log_msg(msg);
}

static void apply_per_iface(void) {
    DIR *d;
    struct dirent *ent;

    d = opendir("/sys/class/net");
    if (!d) return;

    while ((ent = readdir(d)) != NULL) {
        if (ent->d_name[0] == '.') continue;
        if (strcmp(ent->d_name, "lo") == 0) continue;

        if (is_iface_up(ent->d_name)) {
            apply_iface_opts(ent->d_name);
        }
    }
    closedir(d);
}

static void log_current_dns(void) {
    char cmd[256];
    char dns1[64] = {0}, dns2[64] = {0};
    FILE *p;

    p = popen("getprop net.dns1", "r");
    if (p) {
        fgets(dns1, sizeof(dns1), p);
        pclose(p);
        dns1[strcspn(dns1, "\n")] = '\0';
    }

    p = popen("getprop net.dns2", "r");
    if (p) {
        fgets(dns2, sizeof(dns2), p);
        pclose(p);
        dns2[strcspn(dns2, "\n")] = '\0';
    }

    snprintf(cmd, sizeof(cmd), "current_dns: dns1=%s dns2=%s", dns1, dns2);
    log_msg(cmd);
}

int main(int argc, char *argv[]) {
    struct sigaction sa;
    int cycle = 0;
    char msg[256];

    if (argc > 1 && strcmp(argv[1], "--once") == 0) {
        log_msg("=== NetworkFix v1.0.0 (one-shot apply) ===");
        apply_tcp_opts();
        apply_dns_cache();
        log_current_dns();
        return 0;
    }

    /* Wait for boot completion */
    while (!is_boot_completed()) {
        sleep(2);
    }
    sleep(10);

    if (access(DISABLE_FLAG, F_OK) == 0) {
        return 0;
    }

    /* Setup signal handlers */
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = handle_signal;
    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGINT, &sa, NULL);

    /* Daemonize */
    if (fork() > 0) return 0;
    setsid();

    log_msg("=== NetworkFix v1.0.0 daemon started ===");

    /* Initial apply */
    apply_tcp_opts();
    apply_dns_cache();
    log_current_dns();
    check_connectivity();
    log_network_stats();

    while (running) {
        sleep(APPLY_INTERVAL);

        if (access(DISABLE_FLAG, F_OK) == 0) {
            log_msg("Disable flag found, daemon stopping");
            break;
        }

        cycle++;

        /* Re-apply TCP opts every cycle (some get reset) */
        apply_tcp_opts();

        /* Per-cycle tasks */
        if (cycle % 5 == 0) {
            /* Every 5 minutes: check connectivity */
            check_connectivity();
        }

        if (cycle % 10 == 0) {
            /* Every 10 minutes: log stats and verify DNS */
            log_network_stats();
            log_current_dns();
            apply_per_iface();

            snprintf(msg, sizeof(msg), "cycle=%d (uptime=%lds)", cycle, cycle * APPLY_INTERVAL);
            log_msg(msg);
        }
    }

    log_msg("=== NetworkFix daemon stopped ===");
    return 0;
}
