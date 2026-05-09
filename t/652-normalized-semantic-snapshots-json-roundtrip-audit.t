#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json encode_json);
use Scalar::Util qw(blessed);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $fixture = File::Spec->catfile($repo_root, 'fsm', 'apb_tb.fsm');

subtest 'semantic JSON embedded snapshots survive JSON round trip' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $fixture],
    );

    ok($success, 'semantic JSON command succeeds');
    is(join('', @{$stderr_buf || []}), '', 'semantic JSON keeps stderr clean');
    my $decoded = decode_json(join('', @{$stdout_buf || []}));
    my $roundtrip = decode_json(encode_json($decoded));

    ok(!contains_blessed($roundtrip), 'round-tripped semantic report contains no unexpected blessed values');
    is(
        $roundtrip->{generation_result_snapshot}{summary}{module_name},
        'apb_tb',
        'round-trip report keeps generation snapshot module name',
    );
    is(
        $roundtrip->{semantic}{composition}{plan_snapshot}{top_name},
        'apb_tb',
        'round-trip report keeps composition plan snapshot top name',
    );
    is(
        $roundtrip->{semantic}{composition}{plan_snapshot}{summary}{instance_count},
        2,
        'round-trip report keeps composition plan snapshot instance count',
    );
    is(
        $roundtrip->{diagnostic_summary}{diagnostic_count},
        0,
        'round-trip report keeps diagnostic summary count',
    );
};

done_testing();

sub contains_blessed {
    my ($value) = @_;
    return 0 if blessed($value) && blessed($value) eq 'JSON::PP::Boolean';
    return 1 if blessed($value);
    return 0 unless ref($value);

    if (ref($value) eq 'ARRAY') {
        return 1 if grep { contains_blessed($_) } @$value;
        return 0;
    }

    if (ref($value) eq 'HASH') {
        return 1 if grep { contains_blessed($_) } values %$value;
        return 0;
    }

    return 0;
}
