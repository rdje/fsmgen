use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Test::SourceQueryRunner;

my $work = tempdir(CLEANUP => 1);
my $parser = FSM::Adapter::ISF->new;
my $scheduler = FSM::Scheduler::ISF->new;
my $json = JSON::PP->new->canonical;
write_file("$work/shared.fsm", '(?pkg:shared (+types'
    . ' (type frame (record (flag bit) (payload word)))'
    . ' (type word (signed (two_state (bits 5))))))');
my $word = {kind => 'bits', width => 5, signed => 1, state_model => 'two_state'};
my $frame = {kind => 'record', width => 6, signed => 0,
    member_order => [qw(flag payload)], members => {
        flag => {kind => 'bit', width => 1, signed => 0}, payload => $word,
    }};
my $wrapped = {kind => 'record', width => 11, signed => 0,
    member_order => [qw(head body)], members => {head => $word, body => $frame}};

for my $case (
    ['scalar', '(type alias shared.word)', 'alias', $word, '(set seen packet)'],
    ['record', '(type alias shared.frame)', 'alias', $frame, '(set seen packet.payload)'],
    ['nested_members', '(type alias (record (head shared.word) (body shared.frame)))',
        'alias', $wrapped, '(set seen packet.body.payload)'],
    ['forward_nested', '(type alias nested) (type nested (record (head shared.word) (body shared.frame)))',
        'alias', $wrapped, '(set seen packet.body.payload)'],
) {
    subtest "local imported type $case->[0]" => sub {
        my ($name, $declarations, $alias, $expected, $read) = @$case;
        my $text = '(actor ' . $name . ' (imports (package shared)) (types ' . $declarations . ')'
            . ' (interface (input start) (input packet (type ' . $alias . '))'
            . ' (output seen (width 5)) (output done))'
            . ' (transaction main (on start) ' . $read . ' (complete done)))';
        my $path = "$work/$name.isf";
        write_file($path, $text);
        my $actor;
        my $ok = eval { $actor = $parser->parse_source($text, $path); 1 };
        ok($ok, 'actual source resolves imported alias/member dependencies') or diag($@);
        return unless $ok;
        is($json->encode($actor->{type_symbols}{local}{$alias}), $json->encode($expected),
            'complete independently authored recursive local type identity');
        is_deeply([sort keys %{$actor->{type_symbols}{local}}],
            $name eq 'forward_nested' ? [qw(alias nested)] : ['alias'],
            'imported lookup facts do not leak into local declarations');
        is_deeply([sort keys %{$actor->{type_symbols}{packages}{shared}}], [qw(frame word)],
            'complete imported namespace retains declared package types');
        my ($port) = grep { $_->{name} eq 'packet' } @{$actor->{interface_port_metadata}};
        is($port->{type}, $alias, 'declaration retains local spelling');
        is($port->{width}, $expected->{width}, 'declaration retains imported packed width');
        my $lowered;
        $ok = eval { $lowered = $scheduler->lower($actor); 1 };
        ok($ok, 'actual imported dependency source lowers') or diag($@);
        return unless $ok;
        my $dir = "$work/$name-carriers";
        mkdir $dir or die $!;
        for my $file (sort keys %{$lowered->{files}}) {
            write_file("$dir/$file", $lowered->{files}{$file});
            my $result = FSM::Test::SourceQueryRunner::_capture(
                [$^X, 'bin/fsmgen', '--quiet', '--strict', '--check', '--json', "$dir/$file"], '');
            is($result->{exit_code}, 0, "$file actual carrier strictly replays")
                or diag($result->{stdout} . $result->{stderr});
            my $report = eval { $json->decode($result->{stdout}) };
            ok($report && $report->{success}, "$file records strict success");
        }
    };
}

subtest 'unknown and undeclared imported type dependencies remain closed' => sub {
    for my $case (
        ['missing_member', '(imports (package shared)) (types (type alias shared.missing))',
            'alias', qr/malformed '\+types' entry for type 'alias'/],
        ['unimported_namespace', '(types (type alias shared.word))',
            'alias', qr/malformed '\+types' entry for type 'alias'/],
        ['unqualified_import', '(imports (package shared)) (types (type alias word))',
            'alias', qr/malformed '\+types' entry for type 'alias'/],
        ['unknown_port_type', '(imports (package shared))',
            'shared.missing', qr/interface port 'packet' references unknown type 'shared.missing'/],
    ) {
        my ($name, $declarations, $type, $message) = @$case;
        my $text = '(actor refused ' . $declarations . ' (interface (input packet (type ' . $type . '))))';
        my $ok = eval { $parser->parse_source($text, "$work/$name.isf"); 1 };
        my ($error) = split /\n/, $@;
        ok(!$ok, "$name actual source refuses");
        like($error // '', $message, "$name identifies the first contextual cause");
    }
};

done_testing;
sub write_file {
    open my $fh, '>', $_[0] or die $!;
    print {$fh} $_[1] or die $!;
    close $fh or die $!;
}
