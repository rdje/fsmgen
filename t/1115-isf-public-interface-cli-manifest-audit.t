#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::ISFPublicInterfaceContract qw(
    build_isf_public_interface_contract
    isf_public_interface_contract_source
);

for my $mode ('--capability-manifest', '--emit-capability-manifest') {
    subtest "$mode advertises the ISF public-interface contract" => sub {
        my $manifest = run_manifest($mode);
        my $contract = build_isf_public_interface_contract();

        is_deeply(
            $manifest->{embedding}{isf_public_interface},
            $contract,
            "$mode embeds the ISF public-interface contract",
        );
        is(
            $manifest->{embedding}{section_contract}{nested_contract_source_map}{isf_public_interface},
            isf_public_interface_contract_source(),
            "$mode maps ISF public interface to its contract owner",
        );
    };
}

done_testing();

sub run_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}
