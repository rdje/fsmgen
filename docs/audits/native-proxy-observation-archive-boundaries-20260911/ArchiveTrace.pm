package NativeProxyArchiveTrace;

use strict;
use warnings;
our ($ACTIVE, $ROW, $ROOT, $WRITER_INDEX, $EVIDENCE, $ARCHIVE);
our (%COUNTERS, %SEEN, %FILES, %HANDLES, @HELD);

BEGIN {
    *CORE::GLOBAL::binmode = sub (*;$) {
        if ($ACTIVE && caller eq 'NativeProxyImagePublication') {
            _handle($_[0], "writer:$WRITER_INDEX", 'writer', $FILES{by_index}[$WRITER_INDEX], $WRITER_INDEX);
            _event("writer:$WRITER_INDEX:binmode");
        }
        return @_ == 1 ? CORE::binmode($_[0]) : CORE::binmode($_[0], $_[1]);
    };
    *CORE::GLOBAL::mkdir = sub ($;$) {
        my $selected = $ACTIVE && caller eq 'NativeProxyObservationArchive';
        _event('mkdir:before') if $selected;
        my $ok = @_ == 1 ? CORE::mkdir($_[0]) : CORE::mkdir($_[0], $_[1]);
        my $error = 0+$!;
        _event('mkdir:after') if $selected;
        $! = $error; return $ok;
    };
    *CORE::GLOBAL::opendir = sub (*$) {
        my $ok = CORE::opendir($_[0], $_[1]); my $error = 0+$!;
        if ($ACTIVE && $ok && caller eq 'NativeProxyImageCoordination') {
            my $label = 'directory_handle:'._ordinal('directory_handle');
            _handle($_[0], $label, 'directory', $_[1]);
        }
        $! = $error; return $ok;
    };
    *CORE::GLOBAL::closedir = sub (*) {
        return CORE::closedir($_[0]) unless $ACTIVE && ref($_[0])
            && exists($HANDLES{Scalar::Util::refaddr($_[0])});
        return _close($_[0], 1);
    };
    *CORE::GLOBAL::close = sub (*) {
        return CORE::close($_[0]) unless $ACTIVE && ref($_[0])
            && exists($HANDLES{Scalar::Util::refaddr($_[0])});
        return _close($_[0], 0);
    };
}

use Fcntl qw(S_ISDIR S_ISREG F_GETFD FD_CLOEXEC);
use File::Spec;
use Scalar::Util qw(refaddr);
use FSM::Test::ProcessSupervisor qw(repository_root);
use ArchiveRecord;
use ObservationArchive;

$ROOT = repository_root();

sub _ordinal {
    my ($name) = @_;
    my $value = $COUNTERS{$name} // 0; $COUNTERS{$name} = $value+1;
    return $value;
}

sub _event {
    my ($name) = @_;
    die "observed archive boundary aliases: $name\n" if $SEEN{$name}++;
    push @{$ROW->{events}}, $name;
}

sub _pair {
    my ($name, $callback) = @_;
    _event("$name:before");
    my $value = $callback->();
    _event("$name:after");
    return $value;
}

sub _file_index {
    my ($path) = @_;
    die "unexpected archive file path\n" unless exists($FILES{by_path}{$path});
    return $FILES{by_path}{$path};
}

sub _handle {
    my ($handle, $label, $kind, $path, $index) = @_;
    my $address = refaddr($handle);
    die "duplicate archive handle ownership\n" if exists($HANDLES{$address});
    my $descriptor = fileno($handle);
    die "archive descriptor unavailable\n" unless defined($descriptor) && $descriptor >= 0;
    my @native;
    my $observer;
    if ($kind eq 'directory') {
        die "unexpected archive directory handle\n" unless $path eq $ARCHIVE;
        open my $probe, '<&', $descriptor or die "directory observer duplicate: $!\n";
        @native = stat($probe); $observer = fileno($probe);
        my $closed = CORE::close($probe);
        die "directory observer close failed\n" unless $closed;
        die "directory observer did not close\n" if defined(fileno($probe));
        die "observed handle is not a directory\n" unless @native && S_ISDIR($native[2]);
    } else {
        _file_index($path);
        @native = stat($handle);
        die "observed handle is not a file\n" unless @native && S_ISREG($native[2]);
    }
    my @named = lstat($path);
    die "observed descriptor differs from named archive object\n"
        unless @named && $named[0] == $native[0] && $named[1] == $native[1];
    my $row = {handle => $handle, label => $label, kind => $kind,
        path => File::Spec->abs2rel($path, $ROOT), descriptor => $descriptor,
        device => $native[0], inode => $native[1]};
    $row->{file_index} = $index if defined($index);
    if (defined($observer)) {
        $row->{observer_descriptor} = $observer;
        $row->{observer_closed} = 1;
    }
    $HANDLES{$address} = $row; push @HELD, $row;
    _event("opened:$label");
}

sub _close {
    my ($handle, $directory) = @_;
    my $row = $HANDLES{refaddr($handle)};
    die "archive handle closed twice\n" if exists($row->{actual_close_ok});
    _event("close:$row->{label}:before");
    if ($directory) {
        $row->{cloexec_before_close} = undef;
    } else {
        my $flags = CORE::fcntl($handle, F_GETFD, 0);
        $row->{cloexec_before_close} = defined($flags) && ($flags & FD_CLOEXEC) ? 1 : 0;
    }
    $! = 0;
    my $ok = $directory ? CORE::closedir($handle) : CORE::close($handle);
    my $error = 0+$!;
    $row->{actual_close_ok} = $ok ? 1 : 0; $row->{actual_errno} = $error;
    $row->{closed_after_call} = defined(fileno($handle)) ? 0 : 1;
    _event("close:$row->{label}:after");
    $! = $error; return $ok;
}

sub observe_archive {
    die "expected one complete inert context\n" unless @_ == 1;
    my ($context) = @_;
    die "nested archive observation\n" if $ACTIVE;
    my $case = $context->{store}{path};
    my $spec = NativeProxyObservationArchiveRecord::archive_specification($case, $context->{request}, $context->{acquired});
    local $ROW = {events => [], reads => [], writes => [], directories => []};
    local (%COUNTERS, %SEEN, %HANDLES, @HELD);
    local %FILES = (by_index => [map { "$ROOT/$_->{path}" } @{$spec->{files}}], by_path => {});
    $FILES{by_path}{$FILES{by_index}[$_]} = $_ for 0..$#{$FILES{by_index}};
    local $EVIDENCE = "$ROOT/$context->{evidence}{path}";
    local $ARCHIVE = "$ROOT/$spec->{archive_directory}";
    local $WRITER_INDEX;
    my %original = (
        limits => \&NativeProxyObservationArchive::_limits,
        prior => \&NativeProxyObservationAcquisition::_prior_directory,
        directory => \&NativeProxyImageCustody::_directory,
        directory_closure => \&NativeProxyObservationArchive::_directory_closure,
        members => \&NativeProxyObservationArchive::_members,
        names => \&NativeProxyImageCoordination::_names,
        source => \&NativeProxyImageCustody::_source,
        lower_reader => \&FSM::Test::RustProxyFixture::_read_file,
        recheck => \&NativeProxyImageCustody::_recheck_source,
        write => \&NativeProxyImagePublication::_write_payload,
        seal => \&NativeProxyImagePublication::_seal_payload,
        source_closure => \&NativeProxyObservationArchive::_source_closure,
        receipt => \&NativeProxyObservationArchive::_receipt,
        close_sources => \&NativeProxyObservationArchive::_close_sources);
    no warnings 'redefine';
    local *NativeProxyObservationArchive::_limits = sub {
        my @args = @_; return _pair('limits', sub { $original{limits}->(@args) });
    };
    local *NativeProxyObservationAcquisition::_prior_directory = sub {
        my @args = @_; return _pair('prior:'._ordinal('prior'), sub { $original{prior}->(@args) });
    };
    local *NativeProxyImageCustody::_directory = sub {
        my @args = @_;
        my $role = $args[0] eq $EVIDENCE ? 'evidence' : $args[0] eq $ARCHIVE ? 'archive'
            : die "original target directory attempted\n";
        push @{$ROW->{directories}}, File::Spec->abs2rel($args[0], $ROOT);
        return _pair("directory:$role:"._ordinal("directory:$role"), sub { $original{directory}->(@args) });
    };
    local *NativeProxyObservationArchive::_directory_closure = sub {
        my @args = @_; return _pair('directory_closure:'._ordinal('directory_closure'), sub { $original{directory_closure}->(@args) });
    };
    local *NativeProxyObservationArchive::_members = sub {
        my @args = @_; return _pair('members:'._ordinal('members'), sub { $original{members}->(@args) });
    };
    local *NativeProxyImageCoordination::_names = sub {
        my @args = @_; return _pair('names:'._ordinal('names'), sub { $original{names}->(@args) });
    };
    local *FSM::Test::RustProxyFixture::_read_file = sub {
        _file_index($_[0]); push @{$ROW->{reads}}, File::Spec->abs2rel($_[0], $ROOT);
        return $original{lower_reader}->(@_);
    };
    local *NativeProxyImageCustody::_source = sub {
        my $index = _file_index($_[0]);
        my $label = "source:$index:"._ordinal("source:$index");
        _event("$label:before");
        my $source = $original{source}->(@_);
        _handle($source->{handle}, $label, 'source', $source->{path}, $index);
        return $source;
    };
    local *NativeProxyImageCustody::_recheck_source = sub {
        my @args = @_;
        my $label = $HANDLES{refaddr($args[0]{handle})}{label};
        die "source recheck without observed ownership\n" unless defined($label);
        return _pair("recheck:$label:"._ordinal("recheck:$label"), sub { $original{recheck}->(@args) });
    };
    local *NativeProxyImagePublication::_write_payload = sub {
        my @args = @_; local $WRITER_INDEX = _file_index($args[0]);
        push @{$ROW->{writes}}, File::Spec->abs2rel($args[0], $ROOT);
        return _pair("write:$WRITER_INDEX", sub { $original{write}->(@args) });
    };
    local *NativeProxyImagePublication::_seal_payload = sub {
        my @args = @_; return _pair("seal:$WRITER_INDEX", sub { $original{seal}->(@args) });
    };
    local *NativeProxyObservationArchive::_source_closure = sub {
        my @args = @_; return _pair('source_closure', sub { $original{source_closure}->(@args) });
    };
    local *NativeProxyObservationArchive::_receipt = sub {
        my @args = @_; return _pair('receipt', sub { $original{receipt}->(@args) });
    };
    local *NativeProxyObservationArchive::_close_sources = sub {
        my @args = @_; return _pair('close_sources', sub { $original{close_sources}->(@args) });
    };
    {
        local $ACTIVE = 1;
        _event('operation:begin');
        my $ok = eval {
            $ROW->{result} = NativeProxyObservationArchive::archive_retained_sources(
                $case, $context->{request}, $context->{acquired});
            _event('operation:end');
            1;
        };
        my $error = $@; $error =~ s/\Q$ROOT\E/./g;
        $ROW->{error} = $error; $ROW->{returned} = $ok && defined($ROW->{result}) ? 1 : 0;
    }
    $ROW->{handles} = [map {
        my %copy = %$_; delete $copy{handle};
        $copy{closed_at_return} = defined(fileno($_->{handle})) ? 0 : 1;
        \%copy;
    } @HELD];
    # Actual aliases remain alive while this verdict is recorded. No destructor
    # or observer close can manufacture the implementation's disposition.
    $ROW->{all_observed_handles_closed} = (grep { !$_->{closed_at_return} } @{$ROW->{handles}}) ? 0 : 1;
    return $ROW;
}

1;
