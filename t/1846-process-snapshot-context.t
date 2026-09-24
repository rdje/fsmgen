#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(getcwd);
use Scalar::Util qw(refaddr);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Support::ProcessSupervisor::Wire ();

my $key = 'FSMGEN_PROCESS_COORDINATOR_CONTEXT';
# Synthetic grammar-only authority: no endpoint, random token or native job.
my $context = join(':', 1, unpack('H*', '.artifacts/tmp/process-coordinator/fixture'), '1' x 32, 2, '2' x 64);
sub error_from { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@ }
sub bounded { FSM::Support::ProcessSupervisor::Wire::snapshot_with_context(@_) }
sub wire { FSM::Support::ProcessSupervisor::Wire::encode_frame('client', $_[0]) }
sub scalar_bytes { pack('N', length $_[0]) . $_[0] }
sub literal {
    my ($s) = @_;
    # Independent fixed SPAWN field order and literal u64 start (2^32 + 5).
    my $body = pack('CCNN', 1, 3, 1, 5)
        . join('', map { scalar_bytes($s->{$_}) } qw(schema stage containment cwd))
        . pack('NNNN', $s->{timeout_seconds}, $s->{capture_limit_bytes}, $s->{umask}, scalar @{$s->{argv}})
        . join('', map { scalar_bytes($_) } @{$s->{argv}})
        . pack('N', scalar @{$s->{environment}})
        . join('', map { scalar_bytes($_->[0]) . scalar_bytes($_->[1]) } @{$s->{environment}});
    return pack('N', length $body) . $body;
}
sub snapshot {
    return {type => 'SPAWN', started_ns => '4294967301', schema => 'snapshot.fixture',
        stage => 'probe', containment => 'fixture-group', cwd => 't', timeout_seconds => 20,
        capture_limit_bytes => 64, umask => 0027,
        argv => ['never-executed', '', "high\xff\n"], environment => []};
}
sub snapshot_bytes {
    my ($s) = @_;
    my $n = 0; $n += length($_) for @{$s->{argv}};
    $n += length($_->[0]) + length($_->[1]) for @{$s->{environment}};
    return $n;
}

subtest 'only exact private context changes and literal execution bytes survive' => sub {
    for my $present (0, 1) {
        my $source = snapshot();
        my @environment = (['A', ''], ($present ? ([$key, 'obsolete-context']) : ()),
            [$key . '_OTHER', 'keep suffix'], ['Z', "space and\nnewline"], ["\xffKEY", "\xfe"]);
        $source->{environment} = \@environment;
        my $original = literal($source);
        my $expected = {%$source, environment => [['A', ''], [$key, $context],
            [$key . '_OTHER', 'keep suffix'], ['Z', "space and\nnewline"], ["\xffKEY", "\xfe"]]};
        my $expected_bytes = literal($expected);
        local %ENV = (FIXTURE_AMBIENT => 'must not merge', $key => 'ambient-is-not-authority');
        my %original_env = %ENV; my $cwd = getcwd(); my $mask = umask();
        my $result = bounded($source, $context);
        is(wire($result), $expected_bytes, 'independent literal SPAWN oracle matches only the selected replacement');
        is(literal($source), $original, 'original snapshot remains unchanged');
        is_deeply(\%ENV, \%original_env, 'pure replacement leaves the selected ambient environment intact');
        ok(getcwd() eq $cwd, 'caller cwd stays unchanged');
        is(umask(), $mask, 'caller umask stays unchanged');
        is($result->{started_ns}, '4294967301', 'original invocation start is preserved exactly');
        is_deeply([@{$result}{qw(cwd umask timeout_seconds capture_limit_bytes)}], ['t', 0027, 20, 64], 'original execution context and bounds stay unchanged');
        isnt(refaddr($result->{argv}), refaddr($source->{argv}), 'argv vector is detached');
        isnt(refaddr($result->{environment}[0]), refaddr($source->{environment}[0]), 'environment pairs are detached');
        $result->{argv}[0] = 'changed result'; $result->{environment}[0][1] = 'changed result';
        is(literal($source), $original, 'mutating the returned structure cannot change input custody');
        $source->{environment}[-1][1] = 'changed source';
        is($result->{environment}[-1][1], "\xfe", 'mutating source cannot change retained output bytes');
    }
};

subtest 'flagged execution scalars normalize once without modifying caller values' => sub {
    my $source = snapshot(); my $snow = chr(0x96ea); my $encoded = pack('H*', 'e99baa');
    $source->{argv} = [$snow, '']; $source->{environment} = [['A', $snow]];
    my $expected = {%$source, argv => [$encoded, ''], environment => [['A', $encoded], [$key, $context]]};
    my $result = bounded($source, $context);
    is(wire($result), literal($expected), 'literal UTF-8 octets agree with the independent wire oracle');
    ok(!utf8::is_utf8($result->{argv}[0]) && !utf8::is_utf8($result->{environment}[0][1]), 'returned execution values are unflagged octets');
    ok(utf8::is_utf8($source->{argv}[0]) && $source->{argv}[0] eq $snow, 'input keeps its original flagged scalar');
};

subtest 'context syntax is validated independently of live submission authority' => sub {
    my $source = snapshot(); my $original = literal($source);
    my $flagged = $context; utf8::upgrade($flagged);
    for my $bad (undef, '', 'invalid', "bad\0context", $flagged, $context . ':extra',
        $context =~ s/^1:/2:/r, $context =~ s/:2:/:0:/r) {
        ok(length(error_from(sub { bounded($source, $bad) })), 'malformed or non-octet context is refused');
        is(literal($source), $original, 'context refusal preserves original snapshot');
    }
    my $different = $context =~ s/:2:/:3:/r;
    my $result = bounded($source, $different);
    ok($result->{environment}[0][1] eq $different, 'valid synthetic syntax transforms without claiming a live endpoint or original grant');
    ok(length(error_from(sub { bounded($source) })), 'missing context refuses');
    ok(length(error_from(sub { bounded($source, $context, 'extra') })), 'additional transformation arguments refuse');
};

subtest 'invalid incoming snapshots cannot be repaired by dropping the old private entry' => sub {
    for my $case (qw(duplicate unordered nul oversized wrong_type extra_field)) {
        my $source = snapshot();
        if ($case eq 'duplicate') { $source->{environment} = [[$key, 'a'], [$key, 'b']]; }
        elsif ($case eq 'unordered') { $source->{environment} = [['Z', 'before'], [$key, 'after']]; }
        elsif ($case eq 'nul') { $source->{environment} = [[$key, "old\0value"]]; }
        elsif ($case eq 'oversized') { $source->{environment} = [[$key, 'x' x 65537]]; }
        elsif ($case eq 'wrong_type') { $source->{type} = 'HELLO'; }
        else { $source->{extra} = 'not admitted'; }
        my $original_env = $source->{environment};
        my @original = map { [@$_] } @$original_env;
        ok(length(error_from(sub { bounded($source, $context) })), "$case input refuses before transformation");
        is(refaddr($source->{environment}), refaddr($original_env), 'failed transformation leaves original vector custody');
        is_deeply($source->{environment}, \@original, 'failed transformation leaves even the invalid input bytes intact');
    }
};

subtest 'environment count is inclusive after insertion or replacement' => sub {
    for my $count (4095, 4096) {
        my $source = snapshot(); $source->{argv} = ['p'];
        $source->{environment} = [map { [sprintf('A%04d', $_), ''] } 1 .. $count];
        my $original = literal($source); my ($result, $error);
        $error = error_from(sub { $result = bounded($source, $context) });
        if ($count == 4095) {
            is($error, '', 'last available environment pair accepts the private context');
            is(scalar @{$result->{environment}}, 4096, 'insertion fills the inclusive pair count');
            my $expected = {%$source, environment => [@{$source->{environment}}, [$key, $context]]};
            ok(wire($result) eq literal($expected), 'boundary output has independent literal framing');
        }
        else { ok(length($error) && !defined($result), 'first excess after insertion publishes no snapshot'); }
        ok(literal($source) eq $original, 'count refusal or success cannot change the original');
    }
    my $source = snapshot(); $source->{argv} = ['p'];
    $source->{environment} = [(map { [sprintf('A%04d', $_), ''] } 1 .. 4095), [$key, 'old']];
    my $result = bounded($source, $context);
    is(scalar @{$result->{environment}}, 4096, 'replacement at full count adds no duplicate entry');
};

subtest 'aggregate execution bytes are revalidated after context growth' => sub {
    for my $excess (0, 1) {
        my $source = snapshot(); $source->{argv} = ['p'];
        my $remaining = 524288 + $excess - 1 - length($key) - length($context) - 8 * 3;
        my @pairs;
        for my $n (0 .. 7) {
            my $size = $remaining > 65536 ? 65536 : $remaining;
            push @pairs, [sprintf('A%02d', $n), 'v' x $size]; $remaining -= $size;
        }
        is($remaining, 0, 'independent fixture fills only admitted scalar widths');
        $source->{environment} = [@pairs, [$key, '']];
        my $original = literal($source); my ($result, $error);
        my $expected = {%$source, environment => [@pairs, [$key, $context]]};
        is(snapshot_bytes($expected), 524288 + $excess, 'independent byte sum fixes the exact transformed boundary');
        $error = error_from(sub { $result = bounded($source, $context) });
        if ($excess) { ok(length($error) && !defined($result), 'first excess from a valid shorter input publishes no transformed snapshot'); }
        else { is($error, '', 'inclusive aggregate bound succeeds'); ok(wire($result) eq literal($expected), 'maximum admitted aggregate has exact literal framing'); }
        ok(literal($source) eq $original, 'aggregate boundary handling leaves original bytes intact');
    }
};

done_testing;
