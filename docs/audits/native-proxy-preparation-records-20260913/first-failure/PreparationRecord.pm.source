package NativeProxyPreparationRecord;

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use JSON::PP ();

# Inactive data codec. These historical identities are not current filesystem
# observations. A valid record never grants execution or storage authority.
my $JSON = JSON::PP->new->canonical->ascii->max_depth(16)->allow_nonref(0);
my $SCALAR = JSON::PP->new->canonical->ascii->allow_nonref(1);
my $STORE = '.artifacts/cache/rust-proxy-images/v1';
my $WORKSPACE = qr{\.artifacts/tmp/process-supervisor-tests/fsmgen-[A-Za-z0-9_]+};
my $LIMIT = 65_536;

sub _fields {
    my ($record, @fields) = @_;
    die "expected closed record fields\n" unless ref($record) eq 'HASH'
        && keys(%$record) == @fields && !grep { !exists($record->{$_}) } @fields;
}

sub _string {
    my ($value) = @_;
    die "expected JSON string\n" unless defined($value) && !ref($value)
        && $SCALAR->encode($value) =~ /\A"/;
    return $value;
}

sub _integer {
    my ($value) = @_;
    die "expected nonnegative JSON integer\n" unless defined($value) && !ref($value)
        && $SCALAR->encode($value) =~ /\A(?:0|[1-9][0-9]*)\z/;
    return $value;
}

sub _bit {
    my ($value) = @_;
    die "expected integer zero or one\n" unless _integer($value) <= 1;
    return $value;
}

sub _digest {
    my ($value) = @_;
    die "expected lowercase SHA-256\n" unless _string($value) =~ /\A[0-9a-f]{64}\z/;
    return $value;
}

sub _same {
    my ($left, $right, $message) = @_;
    die "$message\n" unless $JSON->encode($left) eq $JSON->encode($right);
}

sub _source {
    my ($source, $path, $limit) = @_;
    _fields($source, qw(path device inode size_bytes sha256));
    die "source path differs from fixed layout\n" unless _string($source->{path}) eq $path;
    _integer($source->{$_}) for qw(device inode size_bytes);
    _digest($source->{sha256});
    die "source exceeds byte ceiling\n" if $source->{size_bytes} > $limit;
}

sub _pairs {
    my ($record) = @_;
    my ($private, $selected) = @$record{qw(compilation_sources sources)};
    die "expected available compilation source prefix\n"
        unless ref($private) eq 'ARRAY' && @$private <= 2;
    die "expected selected source pair or empty list\n"
        unless ref($selected) eq 'ARRAY' && (@$selected == 0 || @$selected == 2);
    my ($workspace, $image_key);
    if (@$private) {
        my $path = ref($private->[0]) eq 'HASH' ? $private->[0]{path} : undef;
        die "expected private generated C path\n"
            unless _string($path) =~ /\A($WORKSPACE)\/rust-tools\/rustup\.c\z/;
        $workspace = $1;
        my @names = qw(rustup.c rustup);
        _source($private->[$_], "$workspace/rust-tools/$names[$_]", $LIMIT) for 0..$#$private;
    }
    if (@$selected) {
        my $path = ref($selected->[0]) eq 'HASH' ? $selected->[0]{path} : undef;
        die "expected canonical generated C path\n"
            unless _string($path) =~ /\A\Q$STORE\E\/images\/([0-9a-f]{64})\/rustup\.c\z/;
        $image_key = $1;
        my @names = qw(rustup.c rustup);
        _source($selected->[$_], "$STORE/images/$image_key/$names[$_]", $LIMIT) for 0, 1;
        die "selected image requires complete compilation sources\n" unless @$private == 2;
        for my $index (0, 1) {
            _same([@{$private->[$index]}{qw(size_bytes sha256)}],
                  [@{$selected->[$index]}{qw(size_bytes sha256)}],
                  'selected image bytes differ from compilation identities');
        }
    }
    return ($workspace, $image_key);
}

sub _reference {
    my ($reference, $workspace, $image_key, $selected) = @_;
    _fields($reference, qw(record global private));
    my $record = $reference->{record};
    _fields($record, qw(schema reference_key image_key workspace workspace_identity selected_sources));
    die "expected complete selected image before reference\n" unless defined($workspace) && defined($image_key);
    die "expected runtime reference schema\n"
        unless _string($record->{schema}) eq 'fsmgen.test.rust_proxy_image_reference.v1';
    die "reference workspace or image differs\n"
        unless _string($record->{workspace}) eq $workspace && _digest($record->{image_key}) eq $image_key;
    my $key = sha256_hex("fsmgen.rust_proxy_reference.runtime.v1\0" . $workspace);
    die "runtime reference key differs from workspace\n" unless _digest($record->{reference_key}) eq $key;
    my $directory = $record->{workspace_identity};
    _fields($directory, qw(path device inode));
    die "reference workspace identity differs\n" unless _string($directory->{path}) eq $workspace;
    _integer($directory->{$_}) for qw(device inode);
    _same($record->{selected_sources}, $selected, 'reference selected sources differ');
    my $bytes = $JSON->encode($record);
    die "runtime reference exceeds byte ceiling\n" if length($bytes) > 4096;
    for my $item (['global', "$STORE/references/$key.json"],
                  ['private', "$workspace/rust-tools/image-reference.json"]) {
        my ($name, $path) = @$item;
        _source($reference->{$name}, $path, 4096);
        die "reference byte identity differs from canonical record\n"
            unless $reference->{$name}{size_bytes} == length($bytes)
                && $reference->{$name}{sha256} eq sha256_hex($bytes);
    }
}

sub _compilation {
    my ($record, $workspace) = @_;
    my ($compilation, $argv) = @$record{qw(compilation compilation_argv)};
    if (defined($argv)) {
        die "expected compiler argv and known private workspace\n"
            unless defined($workspace) && ref($argv) eq 'ARRAY' && @$argv == 16;
        _string($_) for @$argv;
        my ($compiler, $sdk) = @$argv[0,3];
        die "compiler or SDK differs from selected read-only toolchain\n"
            unless $compiler eq '/Library/Developer/CommandLineTools/usr/bin/clang'
                && $sdk =~ m{\A/Library/Developer/CommandLineTools/SDKs/MacOSX(?:[0-9]+(?:\.[0-9]+)*)?\.sdk\z};
        my @expected = ($compiler, '--no-default-config', '-isysroot', $sdk, '-arch', 'arm64',
            '-mmacosx-version-min=11.0', '-O2', '-Wall', '-Wextra', '-Werror', '-fno-builtin',
            '-fno-modules', "$workspace/rust-tools/rustup.c", '-o', "$workspace/rust-tools/rustup");
        _same($argv, \@expected, 'compiler argv differs from sealed preparation policy');
    }
    return unless defined($compilation);
    die "compilation requires retained argv\n" unless defined($argv);
    _fields($compilation, qw(schema schema_version stage ok status diagnostic stdout stderr stdout_bytes stderr_bytes
        exit_code signal timed_out output_limited exec_failed exec_error timeout_seconds capture_limit_bytes
        started_monotonic_ns exec_handoff_monotonic_ns first_output_monotonic_ns finished_monotonic_ns
        spawn_to_exec_ns execution_ns exec_to_first_output_ns first_output_to_exit_ns cleanup));
    die "compilation schema, stage or bounds differ\n"
        unless _string($compilation->{schema}) eq 'fsmgen.test.rust_proxy_compilation.v1'
            && _integer($compilation->{schema_version}) == 1
            && _string($compilation->{stage}) eq 'compile_proxy'
            && _integer($compilation->{timeout_seconds}) == 10
            && _integer($compilation->{capture_limit_bytes}) == 4096;
    _bit($compilation->{$_}) for qw(ok timed_out output_limited exec_failed);
    my $status = _string($compilation->{status});
    die "unknown compilation status\n" unless $status =~ /\A(?:success|invocation_error|host_error|timed_out|output_limited|exec_error|surviving_descendants|cleanup_failed|signaled|nonzero_exit)\z/;
    die "compilation truth differs from status\n" unless $compilation->{ok} == ($status eq 'success' ? 1 : 0);
    _string($compilation->{diagnostic});
    _string($compilation->{exec_error}) if defined($compilation->{exec_error});
    for my $stream (qw(stdout stderr)) {
        my $bytes = _string($compilation->{$stream});
        die "compiler output is not a retained octet string\n" if $bytes =~ /[^\x00-\xff]/;
        die "compiler output length differs\n" unless length($bytes) == _integer($compilation->{$stream . '_bytes'});
    }
    die "compiler output exceeds aggregate bound\n" if $compilation->{stdout_bytes} + $compilation->{stderr_bytes} > 4096;
    for my $field (qw(exit_code signal started_monotonic_ns exec_handoff_monotonic_ns first_output_monotonic_ns
            finished_monotonic_ns spawn_to_exec_ns execution_ns exec_to_first_output_ns first_output_to_exit_ns)) {
        _integer($compilation->{$field}) if defined($compilation->{$field});
    }
    my $cleanup = $compilation->{cleanup};
    _fields($cleanup, qw(containment leader_started term_sent kill_sent leader_reaped group_gone surviving_descendants));
    die "compiler containment differs\n" unless _string($cleanup->{containment}) eq 'rust_proxy_compiler_group';
    _bit($cleanup->{$_}) for qw(leader_started term_sent kill_sent leader_reaped group_gone surviving_descendants);
    die "successful compiler outcome contradicts exit evidence\n"
        if $compilation->{ok} && (!defined($compilation->{exit_code}) || $compilation->{exit_code} != 0
            || !defined($compilation->{signal}) || $compilation->{signal} != 0
            || $compilation->{timed_out} || $compilation->{output_limited} || $compilation->{exec_failed}
            || defined($compilation->{exec_error}) || $cleanup->{surviving_descendants});
}

sub _validate {
    my ($record) = @_;
    _fields($record, qw(schema ok status failure_stage diagnostic implementation selection_reason executable
        sources compilation compilation_argv compilation_sources image_reference));
    die "expected shared native preparation version\n"
        unless _string($record->{schema}) eq 'fsmgen.test.rust_proxy_fixture.v2'
            && _string($record->{implementation}) eq 'native'
            && _string($record->{selection_reason}) eq 'darwin_arm64_command_line_tools';
    _bit($record->{ok});
    die "preparation diagnostic exceeds character bound\n" if length(_string($record->{diagnostic})) > 2048;
    my ($workspace, $key) = _pairs($record);
    _compilation($record, $workspace);
    _reference($record->{image_reference}, $workspace, $key, $record->{sources})
        if defined($record->{image_reference});
    my @identities = (@{$record->{compilation_sources}}, @{$record->{sources}});
    if (defined($record->{image_reference})) {
        push @identities, @{$record->{image_reference}}{qw(global private)};
        push @identities, $record->{image_reference}{record}{workspace_identity};
    }
    my ($device, %seen);
    for my $identity (@identities) {
        $device = $identity->{device} unless defined($device);
        die "cross-volume or aliased retained identities\n"
            unless $identity->{device} == $device && !$seen{$identity->{inode}}++;
    }
    my $status = _string($record->{status});
    my $compilation = $record->{compilation};
    my $settled = defined($compilation) && $compilation->{ok}
        && $compilation->{cleanup}{leader_reaped} && $compilation->{cleanup}{group_gone};
    die "image selection precedes settled compilation\n" if @{$record->{sources}} && !$settled;
    if ($record->{ok}) {
        die "successful preparation lacks complete settled inputs\n"
            unless $status eq 'success' && !defined($record->{failure_stage})
                && defined($key) && defined($record->{image_reference})
                && $settled;
        die "successful preparation executable differs\n"
            unless _string($record->{executable}) eq "$STORE/images/$key/rustup";
    }
    else {
        die "failed preparation exposes an executable\n" if defined($record->{executable});
        die "failed preparation has success status\n" if $status eq 'success';
        die "unknown preparation failure status\n" unless $status =~ /\A(?:invocation_error|host_error|timed_out|output_limited|exec_error|surviving_descendants|cleanup_failed|signaled|nonzero_exit)\z/;
        my $stage = _string($record->{failure_stage});
        die "unknown preparation failure stage\n" unless $stage =~ /\A(?:invocation|workspace|source|compile|artifact_admission|image_admission|image_reference)\z/;
        die "failed preparation lacks a diagnostic\n" unless length($record->{diagnostic});
        die "non-compile failure must retain invocation_error\n"
            if $stage ne 'compile' && $status ne 'invocation_error';
        die "early failure contains later source identities\n"
            if ($stage =~ /\A(?:invocation|workspace)\z/ && @{$record->{compilation_sources}})
                || ($stage eq 'source' && @{$record->{compilation_sources}} > 1);
        die "pre-compile failure contains later compilation evidence\n"
            if $stage =~ /\A(?:invocation|workspace|source)\z/
                && (defined($compilation) || defined($record->{compilation_argv}) || @{$record->{sources}});
        die "post-compile failure lacks settled compilation\n"
            if $stage =~ /\A(?:artifact_admission|image_admission|image_reference)\z/ && !$settled;
        die "image failure lacks complete compilation sources\n"
            if $stage =~ /\Aimage_(?:admission|reference)\z/ && @{$record->{compilation_sources}} != 2;
        die "image acquisition failure must retain invocation_error\n"
            if $stage =~ /\Aimage_(?:admission|reference)\z/ && $status ne 'invocation_error';
        die "compilation failure outcome was rewritten\n"
            if defined($compilation) && !$compilation->{ok}
                && ($stage ne 'compile' || $status ne $compilation->{status});
        if ($stage eq 'compile') {
            die "compile failure contains later source evidence\n" if @{$record->{compilation_sources}} > 1;
            die "compile failure contradicts retained outcome\n"
                if $settled || (defined($compilation) && $compilation->{ok} && $status ne 'cleanup_failed')
                    || (!defined($compilation) && $status ne 'invocation_error');
        }
    }
    return 1;
}

sub encode_preparation_record {
    die "expected one native preparation record\n" unless @_ == 1;
    _validate($_[0]);
    my $bytes = $JSON->encode($_[0]);
    die "preparation record exceeds byte ceiling\n" if length($bytes) > $LIMIT;
    return $bytes;
}

sub decode_preparation_record {
    die "expected one native preparation byte record\n" unless @_ == 1;
    my ($bytes) = @_;
    die "expected bounded ASCII preparation bytes\n" unless defined($bytes) && !ref($bytes)
        && !utf8::is_utf8($bytes) && length($bytes) <= $LIMIT && $bytes !~ /[^\x00-\x7f]/;
    my $record = eval { $JSON->decode($bytes) };
    die "invalid preparation JSON\n" if $@;
    die "preparation JSON is not canonical\n" unless $bytes eq encode_preparation_record($record);
    return $record;
}

1;
