use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::LoweringIR;

my $json = JSON::PP->new->canonical;
my $work = tempdir(CLEANUP => 1);

subtest 'static scalar selectors follow only their declared drive parameter root' => sub {
    my $map = {packet => 'publish_packet', mode => 'publish_mode'};
    for my $case (
        ['packet', 'publish_packet'], ['packet[0]', 'publish_packet[0]'],
        ['packet[4:1]', 'publish_packet[4:1]'], ['packet[1:4]', 'publish_packet[1:4]'],
        ['packet[4:4]', 'publish_packet[4:4]'], ['mode[0]', 'publish_mode[0]'],
        ['packet_more[0]', 'packet_more[0]'], ['held.data', 'held.data'],
        ['packet.data', 'packet.data'], ['mode.ON', 'mode.ON'],
        ['packet[0][0]', 'packet[0][0]'], ['packet[index]', 'packet[index]'],
        ['0', '0'], [7, 7], [undef, undef],
        [['+', 'packet[3:1]', ['&', 'packet[0]', 'scalar[0]']],
         ['+', 'publish_packet[3:1]', ['&', 'publish_packet[0]', 'scalar[0]']]],
    ) {
        my $before = $json->encode([$case->[0], $map]);
        my $got = FSM::Scheduler::ISF::LoweringIR::_substitute_named_drive_body_expr($case->[0], $map);
        is($json->encode($got), $json->encode($case->[1]), 'entire independently authored selector/expression identity');
        is($json->encode([$case->[0], $map]), $before, 'complete caller values and parameter map remain unchanged');
    }
};

for my $case (0, 1, 2) {
    my $domains = $case != 0;
    my $generated = $case == 2;
    my $label = $generated ? 'authored generated drive keeps its invocation-specific parameter selectors'
        : $domains ? 'authored domain scalar drive does not create a foreign input port'
        : 'authored ordinary scalar drive does not read the masked record';
    subtest $label => sub {
        my $system = $domains ? '(clock-domains (domain core (clock clk) :default) (domain aux (clock aux_clk)))'
            : '(clock clk)';
        my $foreign = $domains ? '(domain aux)' : '';
        my $body = $generated ? '(transaction worker (ports (input data (width 5))) (drive publish data) (complete done))'
            . ' (transaction main (on start) (spawn worker as job (bind (input data scalar))) (await_all done) (complete done))'
            : '(transaction main (on start) (drive publish scalar) (complete done))';
        my $text = '(actor selector_drive ' . $system
            . ' (types (type frame (record (flag bit) (data (bits 5)))))'
            . ' (interface (input start) (input scalar (width 5)) (input packet (type frame) ' . $foreign . ')'
            . ' (output whole (width 5)) (output seen (width 4)) (output bit_seen) (output reversed (width 3)) (output done))'
            . ' (drive (publish packet) (whole packet) (seen packet[3:0]) (bit_seen packet[4]) (reversed packet[1:3]))'
            . ' ' . $body . ')';
        my $path = "$work/" . ($generated ? 'generated' : $domains ? 'domains' : 'ordinary') . '.isf';
        write_file($path, $text);
        my $actor = FSM::Adapter::ISF->new->parse_file($path);
        my $before = $json->encode($actor);
        my $product = FSM::Scheduler::ISF->new->lower($actor);
        is($json->encode($actor), $before, 'complete first-read parsed facts remain unchanged');
        my $owner = $domains ? 'selector_drive__domain_core.fsm' : 'selector_drive.fsm';
        my $carrier = $product->{files}{$owner};
        my $prefix = $generated ? 'job_publish' : 'publish';
        like($carrier, qr/\(\Q${prefix}_packet\E 5\)/, 'existing bare output still owns the five-bit parameter width');
        for my $pair (['whole', "${prefix}_packet"], ['seen', "${prefix}_packet[3:0]"],
            ['bit_seen', "${prefix}_packet[4]"], ['reversed', "${prefix}_packet[1:3]"]) {
            like($carrier, qr/\(<- \(\Q$pair->[0]\E> \Q$pair->[1]\E\) <\Q${prefix}_start\E\)/,
                'actual named drive assignment keeps its private parameter identity');
        }
        unlike($carrier, qr/\(<- \([^()]+> packet\[/, 'no selected RHS reads the masked actor record');
        unlike($carrier, qr/\(packet frame\)/, 'core owner gains no foreign record carrier') if $domains;
        for my $kind ([qw(--strict --check --json)], [qw(--strict --emit-semantic-json)]) {
            my $checked = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', @$kind, $path], '');
            is($checked->{exit_code}, 0, 'actual authored source strictly produces its public product')
                or diag($checked->{stdout} . $checked->{stderr});
            is($checked->{stderr}, '', 'actual machine-report stderr remains clean');
            my $report = eval {$json->decode($checked->{stdout})};
            ok(ref($report) eq 'HASH' && $report->{success}, 'actual complete public product reports success');
        }
        is(read_file($path), $text, 'actual source bytes remain unchanged');
    };
}
done_testing;
sub read_file {open my $file, '<:raw', $_[0] or die $!; local $/; return <$file>}
sub write_file {open my $file, '>:raw', $_[0] or die $!; print {$file} $_[1] or die $!; close $file or die $!}
