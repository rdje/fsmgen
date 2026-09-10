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
    map { "$FindBin::Bin/../$_" } qw(native-proxy-image-custody-20260910
        native-proxy-image-coordination-20260910 native-proxy-image-publication-20260910
        native-proxy-runtime-records-20260910 native-proxy-runtime-census-20260910
        native-proxy-image-maintenance-20260910);
use Digest::SHA qw(sha256_hex);
use Fcntl qw(S_ISDIR S_ISLNK S_ISREG F_GETFD FD_CLOEXEC);
use File::Spec;
use File::Temp ();
use JSON::PP ();
use Test::More;
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir repository_root);
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
use Publication;
use ReferenceCensus;
use ImageMaintenance;

my $ROOT = repository_root();
my $JSON = JSON::PP->new->canonical->ascii;
my $parent = ensure_project_artifact_dir(qw(tmp native-proxy-image-custody cases));
my $log = ensure_project_artifact_dir(qw(logs native-proxy-combined-census-20260910));
my $plan = $JSON->decode(read_bytes("$FindBin::Bin/plan.json"));
my $vector = $JSON->decode(read_bytes("$FindBin::Bin/../native-proxy-image-custody-20260910/vectors.json"));
my ($C, $IMAGE) = map { pack('H*', $_) } @$vector{qw(generated_c_hex image_hex)};
my $inspect = \&NativeProxyReferenceCensus::inspect_references;
my $closure = \&NativeProxyReferenceCensus::_closure;
my $result = {schema => 'fsmgen.inactive_combined_reference_census_qualification.v1',
    success => JSON::PP::false, allocated => [], positive => [], controls => [], late_changes => [], mutants => []};
write_bytes("$log/admission.jsonl", '', 0600);
no warnings 'redefine';
local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die 'forbidden compiler'; };

sub read_bytes {
    open my $fh, '<:raw', $_[0] or die "fixture read: $!";
    my $raw = do { local $/; <$fh> }; close $fh or die $!; return $raw;
}
sub write_bytes {
    my ($path, $raw, $mode) = @_;
    chmod(0600, $path) == 1 or die $! if -e $path;
    open my $fh, '>:raw', $path or die "fixture write: $!";
    print {$fh} $raw or die $!; close $fh or die $!; chmod($mode, $path) == 1 or die $!;
}
sub clone { return $JSON->decode($JSON->encode($_[0])); }
sub save_result {
    $result->{forbidden_process_attempts} = $forbidden;
    write_bytes("$log/qualification.json", JSON::PP->new->canonical->ascii->pretty->encode($result), 0600);
}
sub context {
    my ($callback) = @_;
    my $store = File::Temp->newdir('fsmgen-XXXXXXXX', DIR => $parent, CLEANUP => 1);
    my $case = File::Spec->abs2rel("$store", $ROOT); my @s = lstat("$store");
    my $row = {kind => 'store', path => $case, device => $s[0], inode => $s[1]};
    open my $fh, '>>:raw', "$log/admission.jsonl" or die $!;
    print {$fh} $JSON->encode($row), "\n" or die $!; close $fh or die $!;
    push @{$result->{allocated}}, $row; save_result();
    my $image = NativeProxyImagePublication::publish_image($case, $C, $IMAGE)->{image};
    $callback->($case, $image);
    undef $store;
    die 'inert census store remains' if -e "$ROOT/$case" || -l "$ROOT/$case";
    save_result();
}
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
        } elsif (S_ISLNK($s[2])) {
            $node->{kind} = 'symlink'; $node->{target} = readlink("$ROOT/$path");
        } elsif (S_ISREG($s[2])) {
            die 'oracle byte ceiling' if $s[7] > 65537; my $raw = read_bytes("$ROOT/$path");
            $node->{kind} = 'file'; $node->{links} = $s[3];
            $node->{bytes} = length($raw); $node->{sha256} = sha256_hex($raw);
        } else { $node->{kind} = 'special'; }
    };
    $walk->($base, ''); return \%nodes;
}
sub record_for {
    my ($case, $image, $kind, $index) = @_;
    my @sources = map { clone($_->{identity}) } @{$image->{snapshots}}[0,1];
    for my $i (0, 1) { $sources[$i]{device} = 17; $sources[$i]{inode} = 100 + $i; }
    my $record = {image_key => $image->{key}, selected_sources => \@sources};
    if ($kind eq 'runtime') {
        my $path = ".artifacts/tmp/process-supervisor-tests/fsmgen-CombinedCensus$index";
        die 'synthetic workspace exists' if -e "$ROOT/$path" || -l "$ROOT/$path";
        @$record{qw(schema workspace workspace_identity reference_key)} = (
            'fsmgen.test.rust_proxy_image_reference.v1', $path,
            {path => $path, device => 17, inode => 99}, NativeProxyImageCustody::runtime_reference_key($path));
    } elsif ($kind eq 'observation') {
        my $path = '.artifacts/logs/inert-combined-census';
        die 'synthetic evidence directory exists' if -e "$ROOT/$path" || -l "$ROOT/$path";
        @$record{qw(schema evidence_directory evidence_directory_identity observer_birth target_birth)} = (
            'fsmgen.test.rust_proxy_image_observation_reference.v1', $path, {path => $path, device => 17, inode => 99},
            {pid => 101, ppid => 100, uid => 501, ruid => 501, start_sec => 123, start_usec => 456},
            {pid => 201 + $index, ppid => 200, uid => 501, ruid => 501, start_sec => 124, start_usec => 789});
        $record->{reference_key} = NativeProxyImageCustody::observation_reference_key(
            @$record{qw(evidence_directory observer_birth target_birth)});
    } else { die 'unknown fixture owner kind'; }
    return $record;
}
sub add_reference {
    my ($case, $record, $name) = @_; $name //= "$record->{reference_key}.json";
    my $path = "$ROOT/$case/references/$name";
    write_bytes($path, $JSON->encode($record), 0400); return $path;
}
sub reject_operation {
    my ($name, $case, $callback, $diagnostic, $destination) = @_;
    my $row = {name => $name, case => $case, before => footprint($case)};
    my $value; my $ok = eval { $value = $callback->(); 1 }; my $error = $@;
    @$row{qw(rejected returned diagnostic_matched after)} = (
        $ok ? 0 : 1, defined($value) ? 1 : 0, $error =~ $diagnostic ? 1 : 0, footprint($case));
    push @$destination, $row; save_result();
    ok(!$ok && !$row->{returned} && $row->{diagnostic_matched}
        && $JSON->encode($row->{before}) eq $JSON->encode($row->{after}), $name)
        or do { diag($error || 'unexpected acceptance'); BAIL_OUT('first unexpected combined-census rejection retained'); };
}
save_result();
for my $name (@{$plan->{positive}}) {
    context(sub {
        my ($case, $image) = @_; my @owners;
        if ($name eq 'observation_only') { @owners = map { ['observation', $_, $image] } 0,1; }
        elsif ($name eq 'mixed_images') {
            my $second = NativeProxyImagePublication::publish_image($case, $C, $IMAGE.'second')->{image};
            @owners = (['runtime', 0, $image], ['observation', 0, $image],
                       ['runtime', 1, $second], ['observation', 1, $second]);
        } elsif ($name eq 'mixed_capacity') {
            @owners = map { my $i = $_; map { [$_, $i, $image] } qw(runtime observation) } 0..63;
        } elsif ($name ne 'empty') { die 'unknown planned positive'; }
        add_reference($case, record_for($case, $_->[2], @$_[0,1])) for @owners;
        my $row = {name => $name, case => $case, before => footprint($case)};
        my @descriptors;
        {
            local *NativeProxyReferenceCensus::_closure = sub {
                @descriptors = map { my $flags = fcntl($_->{handle}, F_GETFD, 0);
                    defined($flags) && ($flags & FD_CLOEXEC) ? 1 : 0 } @{$_[2]};
                return $closure->(@_);
            };
            $row->{census} = $inspect->($case);
        }
        $row->{after} = footprint($case); $row->{cloexec_sources} = \@descriptors;
        push @{$result->{positive}}, $row; save_result();
        ok($JSON->encode($row->{before}) eq $JSON->encode($row->{after})
            && @{$row->{census}{references}} == @owners && @descriptors == @owners
            && !grep({ $_ != 1 } @descriptors), "$name retains every owner without filesystem mutation")
            or BAIL_OUT('positive census failed');
        if ($name eq 'mixed_capacity') {
            add_reference($case, record_for($case, $image, 'observation', 64));
            my @rows;
            reject_operation('combined capacity excess', $case, sub { $inspect->($case) }, qr/capacity exceeded/, \@rows);
            $result->{capacity_excess} = $rows[0]; save_result();
        }
    });
}
my %changes = (
    'extra observation field' => [sub { $_[0]{extra} = 0 }, qr/closed record/],
    'merged observation fields' => [sub { $_[0]{'image_key,reference_key'} = delete $_[0]{image_key}; delete $_[0]{reference_key} }, qr/closed record/],
    'birth integer boolean' => [sub { $_[0]{observer_birth}{uid} = JSON::PP::true }, qr/birth integer/],
    'birth key mismatch' => [sub { $_[0]{target_birth}{start_usec}++ }, qr/key differs/],
    'source content mismatch' => [sub { $_[0]{selected_sources}[0]{sha256} = '0' x 64 }, qr/content differs/],
    'source length mismatch' => [sub { $_[0]{selected_sources}[1]{size_bytes}++ }, qr/content differs/],
    'source order' => [sub { @{$_[0]{selected_sources}} = reverse @{$_[0]{selected_sources}} }, qr/source path differs/],
    'absent image' => [sub { $_[0]{image_key} = '0' x 64;
        $_->{path} =~ s{/images/[0-9a-f]+/}{'/images/' . ('0' x 64) . '/'}e for @{$_[0]{selected_sources}} }, qr/absent image/],
    'unknown schema' => [sub { $_[0]{schema} .= '.unknown' }, qr/unknown reference schema/],
    'missing schema' => [sub { delete $_[0]{schema} }, qr/explicit reference schema/],
    'boolean schema' => [sub { $_[0]{schema} = JSON::PP::true }, qr/explicit reference schema/],
);
for my $name (@{$plan->{controls}}) {
    context(sub {
        my ($case, $image) = @_;
        my $record = record_for($case, $image, 'observation', 0);
        my $filename = "$record->{reference_key}.json"; my $diagnostic;
        if (my $change = $changes{$name}) { $change->[0]->($record); $diagnostic = $change->[1]; }
        elsif ($name eq 'runtime fields relabeled as observation') {
            $record = record_for($case, $image, 'runtime', 0); $filename = "$record->{reference_key}.json";
            $record->{schema} = 'fsmgen.test.rust_proxy_image_observation_reference.v1'; $diagnostic = qr/closed record/;
        }
        my $path = add_reference($case, $record, $name eq 'wrong filename' ? ('0' x 64).'.json' : $filename);
        my $callback = sub { $inspect->($case) };
        if ($name eq 'wrong filename') { $diagnostic = qr/filename differs/; }
        elsif ($name eq 'duplicate member') { write_bytes($path, '{"schema":"discarded",'.substr($JSON->encode($record),1), 0400); $diagnostic = qr/not canonical/; }
        elsif ($name eq 'partial JSON') { write_bytes($path, '{', 0400); $diagnostic = qr/invalid reference JSON/; }
        elsif ($name eq 'writable reference') { chmod(0600,$path)==1 or die $!; $diagnostic = qr/source mode/; }
        elsif ($name eq 'hardlinked reference') { link($path, "$ROOT/$case/references/".('1' x 64).'.json') or die $!; $diagnostic = qr/source mode/; }
        elsif ($name eq 'legacy inspection rejects observation') {
            $callback = sub { NativeProxyReferenceCensus::inspect_runtime_references($case) }; $diagnostic = qr/closed record/;
        } elsif ($name eq 'observation pin blocks maintenance') {
            $callback = sub { NativeProxyImageMaintenance::remove_unreferenced_image($case, $image->{key}) };
            $diagnostic = qr/retained by an unresolved reference/;
        } elsif ($name eq 'direct inspection bypass') {
            $callback = sub { NativeProxyReferenceCensus::_inspect_locked($case,{}) }; $diagnostic = qr/sealed coordinator/;
        } elsif ($name eq 'extra argument') { $callback = sub { $inspect->($case,'extra') }; $diagnostic = qr/expected one/; }
        die "unknown planned control $name" unless defined($diagnostic);
        reject_operation($name, $case, $callback, $diagnostic, $result->{controls});
    });
}
for my $name (@{$plan->{late}}) {
    context(sub {
        my ($case, $image) = @_; my $path = add_reference($case, record_for($case,$image,'observation',0));
        my $row = {name => $name, case => $case, before => footprint($case)}; my $value;
        my $ok = eval {
            local *NativeProxyReferenceCensus::_closure = sub {
                if ($name eq 'reference_replaced' || $name eq 'image_replaced') {
                    my $p = $name eq 'reference_replaced' ? $path : "$ROOT/$case/images/$image->{key}/rustup";
                    my $bytes = read_bytes($p); rename($p,"$p.old") or die $!;
                    write_bytes($p,$bytes,$name eq 'reference_replaced' ? 0400 : 0500); unlink("$p.old") or die $!;
                } elsif ($name eq 'reference_bytes_changed') {
                    my $r = $JSON->decode(read_bytes($path)); $r->{evidence_directory_identity}{inode}++;
                    write_bytes($path,$JSON->encode($r),0400);
                } elsif ($name eq 'reference_added') { add_reference($case,record_for($case,$image,'observation',1)); }
                elsif ($name eq 'image_directory_replaced') {
                    my $entry = "$ROOT/$case/images/$image->{key}"; rename($entry,"$entry.old") or die $!;
                    mkdir($entry,0700) or die $!;
                    for my $file (qw(rustup.c rustup image.json)) {
                        rename("$entry.old/$file","$entry/$file") or die $!;
                    }
                    rmdir("$entry.old") or die $!;
                } else { die 'unknown planned late change'; }
                $row->{injected} = footprint($case);
                return $closure->(@_);
            };
            $value = $inspect->($case); 1;
        }; my $error = $@;
        @$row{qw(rejected returned diagnostic_matched after)} = ($ok ? 0 : 1, defined($value) ? 1 : 0,
            $error =~ /(?:changed|replaced)/ ? 1 : 0, footprint($case));
        push @{$result->{late_changes}},$row; save_result();
        ok(!$ok && !$row->{returned} && $row->{diagnostic_matched}
            && $JSON->encode($row->{injected}) eq $JSON->encode($row->{after}), "late $name fails without repair")
            or do { diag($error); BAIL_OUT('late change not detected'); };
    });
}
for my $name (@{$plan->{mutants}}) {
    context(sub {
        my ($case,$image) = @_; my $record = record_for($case,$image,'observation',0); my $value;
        if ($name eq 'omitted content join') {
            $record->{selected_sources}[0]{sha256} = '0' x 64; add_reference($case,$record);
            local *NativeProxyReferenceCensus::_matches_image = sub { return }; $value = $inspect->($case);
        } elsif ($name eq 'omitted filename join') {
            add_reference($case,$record,('0' x 64).'.json');
            local *NativeProxyReferenceCensus::_filename_key = sub { return }; $value = $inspect->($case);
        } elsif ($name eq 'inferred observation schema') {
            $record->{schema} .= '.unknown'; add_reference($case,$record);
            local *NativeProxyReferenceCensus::_decode_record = sub {
                my ($c,$raw) = @_; my $r = $JSON->decode($raw);
                $r->{schema} = 'fsmgen.test.rust_proxy_image_observation_reference.v1';
                return NativeProxyObservationRecord::decode_observation_record($c,$JSON->encode($r));
            };
            $value = $inspect->($case);
        } else { die 'unknown planned mutant'; }
        push @{$result->{mutants}}, {name => $name, case => $case, accepted => $value}; save_result();
        ok(defined($value) && @{$value->{references}}==1,"$name admits independently invalid observation")
            or BAIL_OUT('counterimplementation did not reach return');
    });
}
is($forbidden,0,'no compiler or fixture process attempt');
$result->{success} = Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false;
save_result();
done_testing;
