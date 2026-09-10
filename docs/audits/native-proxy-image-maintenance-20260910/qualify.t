#!/usr/bin/env perl
use strict;
use warnings;
our $forbidden = 0;
BEGIN {
    *CORE::GLOBAL::fork = sub { ++$forbidden; die 'forbidden fork'; };
    *CORE::GLOBAL::system = sub { ++$forbidden; die 'forbidden system'; };
}
use FindBin;
use lib "$FindBin::Bin/../../../perl", "$FindBin::Bin/../../../t/lib",
    "$FindBin::Bin/../native-proxy-image-custody-20260910",
    "$FindBin::Bin/../native-proxy-image-coordination-20260910",
    "$FindBin::Bin/../native-proxy-image-publication-20260910",
    "$FindBin::Bin/../native-proxy-runtime-records-20260910",
    "$FindBin::Bin/../native-proxy-runtime-census-20260910",
    "$FindBin::Bin/../native-proxy-runtime-acquisition-20260910", $FindBin::Bin;
use Digest::SHA qw(sha256_hex);
use Fcntl qw(S_ISDIR S_ISLNK S_ISREG);
use File::Spec;
use File::Temp ();
use JSON::PP ();
use Test::More;
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir repository_root);
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
use ReferenceAcquisition;
use ImageMaintenance;

my $ROOT = repository_root();
my $JSON = JSON::PP->new->canonical->ascii;
my $parent = ensure_project_artifact_dir(qw(tmp native-proxy-image-custody cases));
my $work_parent = ensure_project_artifact_dir(qw(tmp process-supervisor-tests));
my $log = ensure_project_artifact_dir(qw(logs native-proxy-image-maintenance-20260910));
my $plan = $JSON->decode(read_bytes("$FindBin::Bin/plan.json"));
my $vectors = $JSON->decode(read_bytes("$FindBin::Bin/../native-proxy-image-custody-20260910/vectors.json"));
my ($C, $IMAGE) = map { pack('H*', $_) } @$vectors{qw(generated_c_hex image_hex)};
my $publish = \&NativeProxyImagePublication::publish_image;
my $maintain = \&NativeProxyImageMaintenance::remove_unreferenced_image;
my $result = {schema => 'fsmgen.inactive_image_maintenance_qualification.v1', success => JSON::PP::false,
              allocated => [], cuts => [], controls => [], late_changes => []};
write_bytes("$log/admission.jsonl", '', 0600);
no warnings 'redefine';
local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die 'forbidden compiler'; };

sub read_bytes {
    open my $fh, '<:raw', $_[0] or die "fixture read: $!";
    my $bytes = do { local $/; <$fh> }; close $fh or die $!; return $bytes;
}
sub write_bytes {
    my ($path, $bytes, $mode) = @_;
    chmod(0600, $path) == 1 or die $! if -e $path;
    open my $fh, '>:raw', $path or die "fixture write: $!";
    print {$fh} $bytes or die $!; close $fh or die $!; chmod($mode, $path) == 1 or die $!;
}
sub save_result {
    $result->{forbidden_process_attempts} = $forbidden;
    # Keep pretty result formatting separate from the compact JSONL encoder.
    write_bytes("$log/qualification.json", JSON::PP->new->canonical->ascii->pretty->encode($result), 0600);
}
sub allocate {
    my ($kind, $path) = @_; my @s = lstat("$path");
    my $row = {kind => $kind, path => File::Spec->abs2rel("$path", $ROOT), device => $s[0], inode => $s[1]};
    open my $fh, '>>:raw', "$log/admission.jsonl" or die $!;
    print {$fh} $JSON->encode($row), "\n" or die $!; close $fh or die $!;
    push @{$result->{allocated}}, $row; save_result();
}
sub context {
    my ($callback, $without_hold) = @_;
    my $store = File::Temp->newdir('fsmgen-XXXXXXXX', DIR => $parent, CLEANUP => 1);
    allocate('store', $store); my $case = File::Spec->abs2rel("$store", $ROOT);
    my $candidate = $publish->($case, $C, $IMAGE)->{image}{key};
    my $held;
    unless ($without_hold) {
        my $work = File::Temp->newdir('fsmgen-XXXXXXXX', DIR => $work_parent, CLEANUP => 1);
        allocate('workspace', $work); mkdir("$work/rust-tools", 0700) or die $!;
        my @s = stat("$work");
        my $identity = {path => File::Spec->abs2rel("$work", $ROOT), device => $s[0], inode => $s[1]};
        $held = NativeProxyReferenceAcquisition::acquire_runtime_reference($case, $identity, $C, $IMAGE.'held');
        undef $work;
        die 'inert stale owner workspace remains' if -e "$ROOT/$identity->{path}" || -l "$ROOT/$identity->{path}";
    }
    $callback->($case, $candidate, $held);
    my $path = "$store"; undef $store;
    die 'inert maintenance store remains' if -e $path || -l $path;
    save_result();
}
# Independent direct filesystem observation, including unchanged permanent
# lock, all references and other images. No prototype census is reused here.
sub footprint {
    my ($base) = @_; my %nodes; my $walk;
    $walk = sub {
        my ($path, $relative) = @_; my @s = lstat("$ROOT/$path"); die 'oracle stat' unless @s;
        die 'oracle volume/census bound' unless $s[0] == (stat($ROOT))[0] && keys(%nodes) < 512;
        my $node = {device => $s[0], inode => $s[1], mode => $s[2] & 07777, uid => $s[4]};
        $nodes{$relative} = $node;
        if (S_ISDIR($s[2])) {
            $node->{kind} = 'directory'; opendir my $dir, "$ROOT/$path" or die $!;
            my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir $dir; closedir $dir or die $!;
            $walk->("$path/$_", length($relative) ? "$relative/$_" : $_) for @names;
        }
        elsif (S_ISLNK($s[2])) { $node->{kind} = 'symlink'; $node->{target} = readlink("$ROOT/$path"); }
        elsif (S_ISREG($s[2])) {
            die 'oracle byte ceiling' if $s[7] > 65537; my $raw = read_bytes("$ROOT/$path");
            $node->{kind} = 'file'; $node->{links} = $s[3]; $node->{bytes} = length($raw); $node->{sha256} = sha256_hex($raw);
        }
        else { $node->{kind} = 'special'; }
    };
    $walk->($base, ''); return \%nodes;
}
sub replace_file {
    my ($path) = @_; my $raw = read_bytes("$ROOT/$path");
    die 'backup exists' if -e "$ROOT/$path.old" || -l "$ROOT/$path.old";
    rename("$ROOT/$path", "$ROOT/$path.old") or die $!;
    write_bytes("$ROOT/$path", $raw, 0400); unlink("$ROOT/$path.old") == 1 or die $!;
}
sub image_keys { return NativeProxyImageCoordination::_names("$ROOT/$_[0]/images", 32); }

save_result();
for my $expected (@{$plan->{cases}}) {
    context(sub {
        my ($case, $key, $held) = @_;
        my $row = {name => $expected->{name}, case => $case, candidate => $key, held => $held,
                   held_workspace_absent => 1, before => footprint($case), trace => []};
        my $step = sub {
            my ($path, $phase) = @_;
            my $entry = {path => $path eq "$case/images/$key" ? '' : substr($path, length("$case/images/$key/") ), phase => $phase};
            push @{$row->{trace}}, $entry;
            die "selected maintenance cut\n" if defined($expected->{cut}) && $JSON->encode($entry) eq $JSON->encode($expected->{cut});
        };
        my $unlink = \&NativeProxyImageMaintenance::_unlink; my $rmdir = \&NativeProxyImageMaintenance::_rmdir;
        local *NativeProxyImageMaintenance::_unlink = sub { $step->($_[0], 'before'); $unlink->(@_); $step->($_[0], 'after'); };
        local *NativeProxyImageMaintenance::_rmdir = sub { $step->($_[0], 'before'); $rmdir->(@_); $step->($_[0], 'after'); };
        my $value; eval { $value = $maintain->($case, $key); 1 }; $row->{error} = $@;
        $row->{returned} = defined($value) ? 1 : 0; $row->{result} = $value; $row->{after} = footprint($case);
        push @{$result->{cuts}}, $row; save_result();
        my %removed = map { ((length($_) ? "images/$key/$_" : "images/$key") => 1) } @{$expected->{removed}};
        my $remaining = {map { $_ => $row->{before}{$_} } grep { !$removed{$_} } keys %{$row->{before}}};
        ok($row->{returned} == $expected->{returned} && $row->{error} eq ($expected->{returned} ? '' : "selected maintenance cut\n")
            && $JSON->encode($row->{trace}) eq $JSON->encode($expected->{trace})
            && $JSON->encode($row->{after}) eq $JSON->encode($remaining), "maintenance cut: $expected->{name}")
            or do { diag($row->{error}); BAIL_OUT('first unexpected maintenance cut retained'); };
    });
}
sub reject_case {
    my ($name, $prepare, $diagnostic) = @_;
    context(sub {
        my ($case, $key, $held) = @_;
        my @args = ($case, $key); $prepare->($case, $key, $held, \@args);
        my $row = {name => $name, before => footprint($case)}; my $value;
        my $ok = eval { $value = $maintain->(@args); 1 }; my $error = $@;
        $row->{rejected} = $ok ? 0 : 1; $row->{returned} = defined($value) ? 1 : 0;
        $row->{diagnostic_matched} = $error =~ $diagnostic ? 1 : 0; $row->{after} = footprint($case);
        push @{$result->{controls}}, $row; save_result();
        ok(!$ok && !$row->{returned} && $row->{diagnostic_matched} && $JSON->encode($row->{before}) eq $JSON->encode($row->{after}), $name)
            or do { diag($error || 'unexpected acceptance'); BAIL_OUT('first unexpected maintenance rejection retained'); };
    });
}
reject_case('stale owner still pins selected image', sub { $_[3][1] = $_[2]{image}{key} }, qr/retained by an unresolved reference/);
reject_case('absent selected image', sub { $_[3][1] = '0' x 64 }, qr/selected maintenance image is absent/);
reject_case('unknown image name', sub { mkdir("$ROOT/$_[0]/images/unknown", 0700) or die $! }, qr/invalid image name/);
reject_case('partial unreferenced other image', sub { mkdir("$ROOT/$_[0]/images/".('0' x 64), 0700) or die $! }, qr/(?:missing|exist|open|absent)/);
reject_case('partial selected image', sub { unlink("$ROOT/$_[0]/images/$_[1]/image.json") == 1 or die $! }, qr/(?:members|membership|complete)/);
reject_case('changed selected bytes', sub { write_bytes("$ROOT/$_[0]/images/$_[1]/rustup.c", 'changed', 0400) }, qr/(?:key|manifest|differ)/);
reject_case('unknown observation reference', sub {
    my $p = $_[2]{reference}{global}{identity}{path}; my $record = $JSON->decode(read_bytes("$ROOT/$p"));
    $record->{schema} = 'fsmgen.test.rust_proxy_image_observation_reference.v1'; write_bytes("$ROOT/$p", $JSON->encode($record), 0400);
}, qr/runtime reference schema/);
reject_case('malformed reference', sub { write_bytes("$ROOT/$_[2]{reference}{global}{identity}{path}", '{', 0400) }, qr/invalid runtime JSON/);
reject_case('shared selected source', sub { link("$ROOT/$_[0]/images/$_[1]/rustup.c", "$ROOT/$_[0]/images/$_[1]/alias") or die $! }, qr/(?:link|members)/);
reject_case('absent lock cannot be recreated', sub { unlink("$ROOT/$_[0]/coordination.lock") == 1 or die $! }, qr/existing maintenance lock/);
reject_case('unknown store member', sub { rename("$ROOT/$_[0]/references", "$ROOT/$_[0]/unknown") or die $! }, qr/unknown store member/);
reject_case('invalid selected key', sub { $_[3][1] = [] }, qr/JSON string/);
reject_case('extra argument', sub { push @{$_[3]}, 'extra' }, qr/expected inactive store/);
context(sub {
    my ($case) = @_; my $before = footprint($case);
    my $ok = eval { NativeProxyImageMaintenance::_remove_locked($case, {}); 1 }; my $error = $@;
    my $row = {name => 'direct removal bypass', rejected => $ok ? 0 : 1, returned => 0,
               diagnostic_matched => $error =~ /sealed coordinator/ ? 1 : 0, before => $before, after => footprint($case)};
    push @{$result->{controls}}, $row; save_result();
    ok(!$ok && $row->{diagnostic_matched} && $JSON->encode($before) eq $JSON->encode($row->{after}), 'direct removal bypass') or BAIL_OUT('caller bypass');
});
for my $name (qw(source_replaced directory_replaced late_member directory_reappeared)) {
    context(sub {
        my ($case, $key) = @_; my $path = "$case/images/$key";
        my $row = {name => $name, candidate => $key, before => footprint($case)};
        my $remove = \&NativeProxyImageMaintenance::_remove_locked;
        my $unlink = \&NativeProxyImageMaintenance::_unlink; my $rmdir = \&NativeProxyImageMaintenance::_rmdir;
        my $injected = 0;
        local *NativeProxyImageMaintenance::_remove_locked = sub {
            if ($name eq 'source_replaced') { replace_file("$path/rustup.c"); }
            elsif ($name eq 'directory_replaced') {
                die 'directory backup exists' if -e "$ROOT/${path}_old" || -l "$ROOT/${path}_old";
                rename("$ROOT/$path", "$ROOT/${path}_old") or die $!; mkdir("$ROOT/$path", 0700) or die $!;
                rename("$ROOT/${path}_old/$_", "$ROOT/$path/$_") or die $! for qw(rustup.c image.json rustup);
                rmdir("$ROOT/${path}_old") or die $!;
            }
            $row->{injected} = footprint($case) if $name =~ /replaced\z/;
            goto &$remove;
        };
        local *NativeProxyImageMaintenance::_unlink = sub {
            $unlink->(@_); write_bytes("$ROOT/$path/late-added", 'late', 0400) if $name eq 'late_member' && !$injected++;
        };
        local *NativeProxyImageMaintenance::_rmdir = sub {
            $rmdir->(@_); mkdir("$ROOT/$path", 0700) or die $! if $name eq 'directory_reappeared';
        };
        my $value; my $ok = eval { $value = $maintain->($case, $key); 1 }; my $error = $@;
        my $diagnostic = $name eq 'source_replaced' ? qr/candidate source changed/
            : $name eq 'directory_replaced' ? qr/candidate directory changed/
            : $name eq 'late_member' ? qr/cannot remove selected image directory/
            : qr/removed image directory remains present/;
        $row->{rejected} = $ok ? 0 : 1; $row->{returned} = defined($value) ? 1 : 0;
        $row->{diagnostic_matched} = $error =~ $diagnostic ? 1 : 0; $row->{after} = footprint($case);
        push @{$result->{late_changes}}, $row; save_result();
        ok(!$ok && !$row->{returned} && $row->{diagnostic_matched}, "late maintenance change: $name")
            or do { diag($error || 'unexpected acceptance'); BAIL_OUT('late maintenance change'); };
    });
}
context(sub {
    my ($case, $key, $held) = @_;
    $publish->($case, $C, $IMAGE."capacity$_") for 0..29;
    my $row = {before_keys => image_keys($case), held_before => footprint($case)->{'references/' . $held->{reference}{record}{reference_key} . '.json'}};
    my $ok = eval { $publish->($case, $C, $IMAGE.'next'); 1 }; my $error = $@;
    $row->{publication_before_rejected} = !$ok && $error =~ /capacity/ ? 1 : 0;
    $maintain->($case, $key); $row->{after_maintenance_keys} = image_keys($case);
    $publish->($case, $C, $IMAGE.'next'); $row->{after_publication_keys} = image_keys($case);
    $row->{held_after} = footprint($case)->{'references/' . $held->{reference}{record}{reference_key} . '.json'};
    $result->{capacity} = $row; save_result();
    ok($row->{publication_before_rejected} && @{$row->{after_maintenance_keys}} == 31 && @{$row->{after_publication_keys}} == 32,
       'explicit unreferenced maintenance recovers capacity without evicting a hold') or BAIL_OUT('capacity recovery');
});
context(sub {
    my ($case, $key) = @_; my $before = footprint($case)->{'coordination.lock'};
    $maintain->($case, $key);
    my $row = {remaining_images => image_keys($case), references => NativeProxyImageCoordination::_names("$ROOT/$case/references",128),
               lock_before => $before, lock_after => footprint($case)->{'coordination.lock'}};
    $result->{last_image} = $row; save_result();
    ok(!@{$row->{remaining_images}} && !@{$row->{references}} && $JSON->encode($before) eq $JSON->encode($row->{lock_after}),
       'last unreferenced image removal preserves permanent empty store') or BAIL_OUT('last image');
}, 1);
context(sub {
    my ($case, $key, $held) = @_;
    local *NativeProxyImageMaintenance::_referenced = sub { 0 };
    my $value; eval { $value = $maintain->($case, $held->{image}{key}); 1 }; my $error = $@;
    my $row = {removed_despite_pin => !-e "$ROOT/$case/images/$held->{image}{key}" ? 1 : 0,
               reference_retained => -f "$ROOT/$held->{reference}{global}{identity}{path}" ? 1 : 0,
               returned => defined($value) ? 1 : 0, error_matches_missing_image => $error =~ /absent image/ ? 1 : 0};
    $result->{mutant} = $row; save_result();
    ok($row->{removed_despite_pin} && $row->{reference_retained} && !$row->{returned} && $row->{error_matches_missing_image},
       'omitted retention guard destroys pinned bytes before the later census rejects') or do { diag($error); BAIL_OUT('retention mutant'); };
});
is($forbidden, 0, 'no compiler or process attempt');
$result->{success} = Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false;
save_result(); done_testing;
