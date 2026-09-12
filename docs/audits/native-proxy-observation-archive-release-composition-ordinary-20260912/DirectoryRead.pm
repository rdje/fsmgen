package NativeProxyReleaseDirectoryRead;

use strict;
use warnings;
our ($SELECTION, $REPORTS, $HITS);

# Load before the original directory readers compile. Outside the one admitted
# release operation, preserve Perl's scalar/list readdir behavior unchanged.
BEGIN {
    *CORE::GLOBAL::readdir = sub (*) {
        return CORE::readdir($_[0]) unless $NativeProxyReleaseTrace::ACTIVE && defined($SELECTION);
        my $handle = $NativeProxyReleaseTrace::HANDLES{Scalar::Util::refaddr($_[0])};
        return CORE::readdir($_[0]) unless $handle && $handle->{label} eq $SELECTION->{binding}{label};
        die "directory report requires scalar context\n" if wantarray;
        my $bound = $SELECTION->{binding};
        die "directory report differs from actual custody\n" unless $handle->{kind} eq 'directory'
            && $handle->{path} eq $bound->{path} && caller eq $bound->{close_caller}
            && defined(fileno($_[0])) && fileno($_[0]) == $handle->{descriptor};
        die "directory primary repeated\n" if @$REPORTS;
        my $actual = CORE::readdir($_[0]); my $actual_errno = 0 + $!;
        # An unexpected actual read failure remains the original reader's input.
        my $applied = defined($actual) && $actual_errno == 0;
        my $reported = $applied ? undef : $actual;
        my $error = $applied ? Errno::EIO() : $actual_errno;
        push @$REPORTS, {address => $SELECTION->{address}, label => $handle->{label},
            path => $handle->{path}, descriptor => $handle->{descriptor}, device => $handle->{device},
            inode => $handle->{inode}, actual_name => $actual, actual_errno => $actual_errno,
            report_applied => $applied ? 1 : 0, reported_name => $reported, reported_errno => $error};
        ++$HITS if $applied;
        $! = $error;
        return $reported;
    };
}

use Errno ();
use Scalar::Util ();

1;
