#define _POSIX_C_SOURCE 200809L
#include <errno.h>
#include <poll.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

struct identity {
    pid_t pid, ppid, pgid, sid;
    int pgid_errno, sid_errno;
};
struct outcome {
    struct identity before, after;
    int result, error;
};
static volatile sig_atomic_t owned_child;

static void expired(int signal_number) {
    (void)signal_number;
    if (owned_child > 0) kill((pid_t)owned_child, SIGKILL);
    _exit(124);
}

static struct identity identity(pid_t target) {
    struct identity result;
    memset(&result, 0, sizeof(result));
    result.pid = target ? target : getpid();
    result.ppid = target ? -1 : getppid();
    errno = 0;
    result.pgid = getpgid(target);
    result.pgid_errno = errno;
    errno = 0;
    result.sid = getsid(target);
    result.sid_errno = errno;
    return result;
}

static int transfer(int fd, void *buffer, size_t size, int writing) {
    char *cursor = buffer;
    while (size) {
        struct pollfd descriptor = {fd, writing ? POLLOUT : POLLIN, 0};
        int ready;
        do { ready = poll(&descriptor, 1, 2000); } while (ready < 0 && errno == EINTR);
        if (ready != 1) return -1;
        ssize_t count = writing ? write(fd, cursor, size) : read(fd, cursor, size);
        if (count < 0 && errno == EINTR) continue;
        if (count <= 0) return -1;
        cursor += count;
        size -= (size_t)count;
    }
    return 0;
}

static void print_identity(const struct identity *value) {
    printf("{\"pid\":%ld,\"ppid\":%ld,\"pgid\":%ld,\"sid\":%ld,"
           "\"pgid_errno\":%d,\"sid_errno\":%d}",
           (long)value->pid, (long)value->ppid, (long)value->pgid,
           (long)value->sid, value->pgid_errno, value->sid_errno);
}

static int trial(const char *mode, int ordinal) {
    int release[2], observation[2];
    if (pipe(release) || pipe(observation)) return 1;
    pid_t child = fork();
    if (child < 0) return 1;
    if (child == 0) {
        owned_child = 0;
        alarm(5);
        close(release[1]);
        close(observation[0]);
        if (!strcmp(mode, "session_leader") && setsid() != getpid()) _exit(120);
        struct outcome value;
        memset(&value, 0, sizeof(value));
        value.before = identity(0);
        if (transfer(observation[1], &value.before, sizeof(value.before), 1)) _exit(121);
        char token;
        if (transfer(release[0], &token, 1, 0) || token != 'R') _exit(122);
        errno = 0;
        value.result = setpgid(0, 0);
        value.error = errno;
        value.after = identity(0);
        if (transfer(observation[1], &value, sizeof(value), 1)) _exit(123);
        if (transfer(release[0], &token, 1, 0) || token != 'Q') _exit(125);
        close(release[0]);
        close(observation[1]);
        _exit(0);
    }
    owned_child = child;
    alarm(8);
    close(release[0]);
    close(observation[1]);
    struct identity announced;
    struct outcome value;
    int failed = transfer(observation[0], &announced, sizeof(announced), 0);
    struct identity parent_before = identity(child);
    int parent_called = 0, parent_result = 0, parent_error = 0;
    if (!failed && !strcmp(mode, "parent_first")) {
        parent_called = 1;
        errno = 0;
        parent_result = setpgid(child, child);
        parent_error = errno;
    }
    char token = 'R';
    if (!failed) failed = transfer(release[1], &token, 1, 1);
    if (!failed && !strcmp(mode, "simultaneous")) {
        parent_called = 1;
        errno = 0;
        parent_result = setpgid(child, child);
        parent_error = errno;
    }
    if (!failed) failed = transfer(observation[0], &value, sizeof(value), 0);
    if (!failed && !strcmp(mode, "child_first")) {
        parent_called = 1;
        errno = 0;
        parent_result = setpgid(child, child);
        parent_error = errno;
    }
    struct identity parent_after = identity(child);
    token = 'Q';
    if (!failed) failed = transfer(release[1], &token, 1, 1);
    close(release[1]);
    close(observation[0]);
    if (failed) kill(child, SIGKILL);
    int status = 0;
    pid_t waited;
    do { waited = waitpid(child, &status, 0); } while (waited < 0 && errno == EINTR);
    owned_child = 0;
    alarm(0);
    if (failed || waited != child || status != 0) {
        fprintf(stderr, "probe protocol failed mode=%s trial=%d wait=%ld status=%d\n",
                mode, ordinal, (long)waited, status);
        return 1;
    }
    errno = 0;
    int alive = kill(child, 0);
    int absence_errno = errno;
    printf("{\"mode\":\"%s\",\"trial\":%d,\"before\":", mode, ordinal);
    print_identity(&value.before);
    printf(",\"parent_before\":"); print_identity(&parent_before);
    printf(",\"after\":"); print_identity(&value.after);
    printf(",\"parent_after\":"); print_identity(&parent_after);
    printf(",\"child_result\":%d,\"child_errno\":%d,\"parent_called\":%d,"
           "\"parent_result\":%d,\"parent_errno\":%d,\"wait_status\":%d,"
           "\"post_wait_kill_result\":%d,\"post_wait_kill_errno\":%d}\n",
           value.result, value.error, parent_called, parent_result, parent_error,
           status, alive, absence_errno);
    fflush(stdout);
    return 0;
}

int main(void) {
    struct sigaction handler;
    memset(&handler, 0, sizeof(handler));
    handler.sa_handler = expired;
    sigemptyset(&handler.sa_mask);
    if (sigaction(SIGALRM, &handler, NULL)) return 1;
    signal(SIGPIPE, SIG_IGN);
    const char *controls[] = {"child_only", "parent_first", "child_first", "session_leader"};
    for (size_t i = 0; i < sizeof(controls) / sizeof(controls[0]); ++i)
        if (trial(controls[i], 0)) return 1;
    for (int i = 0; i < 64; ++i)
        if (trial("simultaneous", i)) return 1;
    return 0;
}
