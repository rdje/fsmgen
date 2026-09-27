#define _DARWIN_C_SOURCE
#include <errno.h>
#include <limits.h>
#include <sys/types.h>
#include <unistd.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static HV *identity(pid_t target, int caller) {
    HV *value = newHV();
    pid_t pid = target ? target : getpid();
    hv_stores(value, "pid", newSViv(pid));
    if (caller) hv_stores(value, "ppid", newSViv(getppid()));
    errno = 0;
    pid_t group = getpgid(target);
    int group_error = errno;
    errno = 0;
    pid_t session = getsid(target);
    int session_error = errno;
    hv_stores(value, "pgid", newSViv(group));
    hv_stores(value, "pgid_errno", newSViv(group_error));
    hv_stores(value, "sid", newSViv(session));
    hv_stores(value, "sid_errno", newSViv(session_error));
    return value;
}

XS(witness_context) {
    dXSARGS;
    (void)cv;
    if (items != 1) croak("native context requires one target PID");
    IV target = SvIV(ST(0));
    if (target < 0 || target > INT_MAX) croak("native context PID out of range");
    int saved_errno = errno;
    HV *value = newHV();
    hv_stores(value, "caller", newRV_noinc((SV *)identity(0, 1)));
    hv_stores(value, "target", newRV_noinc((SV *)identity((pid_t)target, 0)));
    ST(0) = sv_2mortal(newRV_noinc((SV *)value));
    errno = saved_errno;
    /* Perl 5.34's public macro splits a GNU statement expression across
       macros; suppress only Clang's compatibility warning at this call. */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcompound-token-split-by-macro"
    XSRETURN(1);
#pragma clang diagnostic pop
}
