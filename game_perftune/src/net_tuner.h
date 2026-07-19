#ifndef NET_TUNER_H
#define NET_TUNER_H

typedef struct {
    int tcp_low_latency;
    int tcp_slow_start_after_idle;
    int tcp_no_metrics_save;
} net_state_t;

int net_save_state(net_state_t *state);
int net_apply_boost(void);
int net_restore(const net_state_t *state);
int net_apply_base(void);

#endif
