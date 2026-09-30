use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use Storable qw(dclone);
use JSON::PP;
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::ISFRecordPortScopes qw(
    record_actor_scope record_transaction_scope record_drive_scope
);
use FSM::Support::ISFRecordPortValues qw(record_value_reference);

my $parser = FSM::Adapter::ISF->new;
my $json = JSON::PP->new->canonical;
my $source = <<'ISF';
(actor scopes
  (params (W 8))
  (types (type frame (record (header (bits 2))
      (payload (signed (four_state (bits 6))))))
    (type word (signed (two_state (bits 5)))))
  (interface (input start) (input data (width W)) (output seen (width 8)) (output done))
  (storage (var packet (type frame)) (var backup (type frame)))
  (drive (publish packet) (seen packet))
  (transaction worker (ports (output packet (type word)) (input arg (width W)))
    (local count (width 3) (default 0)) (set packet arg))
  (transaction main (on start) (set seen packet.payload) (complete done)))
ISF
my $actor = $parser->parse_source($source, 'scope-controls.isf');

sub reference {
    my ($scope, $token, $access) = @_;
    return record_value_reference(scope => $scope, token => $token,
        access => $access || 'read', context => 'scope control');
}
sub refuses {
    my ($run, $pattern, $name) = @_;
    my $ok = eval {$run->(); 1};
    my ($line) = split /\n/, $@;
    ok(!$ok, "$name refuses");
    like($line // '', $pattern, "$name names its first-line cause");
}

subtest 'actual finalized actor declarations retain role and type facts' => sub {
    my $scope = record_actor_scope(actor => $actor);
    is_deeply([sort keys %$scope], [qw(backup data done packet seen start)], 'declared roots only');
    is_deeply($scope->{data}, {role => 'input',
        type_spec => {kind => 'bits', width => 8, signed => 0}},
        'resolved symbolic input retains declared width and role');
    is($scope->{packet}{role}, 'storage', 'record root retains storage role');
    is_deeply(reference($scope, 'packet.payload'), {
        root => 'packet', role => 'storage', path_text => '.payload', width => 6, low => 0, high => 5,
        type_spec => {kind => 'bits', width => 6, signed => 1, state_model => 'four_state'},
    }, 'independent packed leaf witness retains signed/state and range');
    is_deeply([@{reference($scope, 'packet.header')}{qw(width low high)}], [2, 6, 7],
        'first authored member is most significant');
    refuses(sub {reference($scope, 'data', 'write')}, qr/cannot write declared input 'data'/,
        'declared actor input cannot become a write');
    my $conflicting = dclone($actor);
    push @{$conflicting->{storage}}, {kind => 'var', name => 'data', width => 8,
        type => 'frame', type_spec => dclone($actor->{storage}[0]{type_spec})};
    is(record_actor_scope(actor => $conflicting)->{data}{role}, 'input',
        'caller-supplied conflicting storage cannot erase a pin role');
    refuses(sub {$parser->parse_source($source =~ s/backup/data/r, 'conflicting.isf')},
        qr/storage signal 'data' conflicts with interface input port 'data'/,
        'projection does not admit authored actor/storage collisions');
    ok(!exists($scope->{publish}) && !exists($scope->{worker}), 'drive and transaction names are not value declarations');
};

subtest 'actual transaction formals and locals mask outer facts' => sub {
    my $scope = record_transaction_scope(actor => $actor, transaction => $actor->{transactions}[0]);
    is_deeply($scope->{packet}, {role => 'output',
        type_spec => {kind => 'bits', width => 5, signed => 1, state_model => 'two_state'}},
        'formal replaces outer record with its own resolved scalar');
    is_deeply($scope->{arg}, {role => 'input', type_spec => {kind => 'bits', width => 8, signed => 0}},
        'formal symbolic width is finalized');
    is_deeply($scope->{count}, {role => 'local', type_spec => {kind => 'bits', width => 3, signed => 0}},
        'explicit local width has no borrowed alias, reset or state overlay');
    is_deeply([@{reference($scope, 'packet[3:1]')}{qw(width low high)}], [3, 1, 3],
        'formal slice resolves against local scalar width');
    refuses(sub {reference($scope, 'packet.payload')}, qr/member_on_non_record/,
        'shadow cannot borrow outer member');
    refuses(sub {reference($scope, 'arg', 'write')}, qr/cannot write declared input 'arg'/,
        'formal input retains its own role');
};

subtest 'unresolved declarations mask without using parser placeholders' => sub {
    my $unresolved = dclone($actor);
    delete $unresolved->{transactions}[0]{ports}{outputs}[0]{type_spec};
    $unresolved->{transactions}[0]{ports}{outputs}[0]{width} = 1;
    my $scope = record_transaction_scope(actor => $unresolved, transaction => $unresolved->{transactions}[0]);
    is_deeply($scope->{packet}, {role => 'output', type_spec => undef},
        'typed formal placeholder remains unknown');
    is(reference($scope, 'packet.payload'), undef, 'unresolved formal never falls through to outer record');
    my $symbolic = $parser->parse_source($source =~ s/\(width 3\)/\(width W\)/r, 'symbolic-local.isf');
    $scope = record_transaction_scope(actor => $symbolic, transaction => $symbolic->{transactions}[0]);
    is_deeply($scope->{count}, {role => 'local', type_spec => undef},
        'local symbolic width is not finalized by actor port-width resolution');
    refuses(sub {FSM::Scheduler::ISF->new->lower($symbolic)}, qr/requires a '\(width N\)' with a positive integer/,
        'projection does not admit unsupported symbolic locals');
    my $local_shadow = dclone($actor);
    push @{$local_shadow->{transactions}[0]{clauses}}, ['local', 'packet', ['width', 'UNKNOWN']];
    $scope = record_transaction_scope(actor => $local_shadow, transaction => $local_shadow->{transactions}[0]);
    is_deeply($scope->{packet}, {role => 'local', type_spec => undef},
        'explicit unresolved local masks formal and actor type facts');
    my $unknown_input = dclone($actor);
    $unknown_input->{interface}{inputs}[1] = {name => 'data', type => 'unresolved', width => 1};
    $scope = record_actor_scope(actor => $unknown_input);
    is_deeply($scope->{data}, {role => 'input', type_spec => undef},
        'unresolved actor input retains role without its placeholder width');
    refuses(sub {reference($scope, 'data', 'write')}, qr/cannot write declared input 'data'/,
        'unknown type cannot erase known input role');
    my $collision = $parser->parse_source($source =~ s/\(local count/\(local data/r, 'local-collision.isf');
    refuses(sub {FSM::Scheduler::ISF->new->lower($collision)},
        qr/collides with interface port 'data'/, 'projection does not admit explicit local pin collisions');
};

subtest 'drive parameter names mask records without inferred type facts' => sub {
    my $scope = record_drive_scope(actor => $actor, drive => $actor->{drives}{publish});
    is_deeply($scope->{packet}, {role => 'local', type_spec => undef}, 'untyped parameter is unknown');
    is(reference($scope, 'packet.payload'), undef, 'parameter cannot inherit actor record layout');
    is(reference($scope, 'seen')->{width}, 8, 'unshadowed actor output retains actual width');
    $scope = record_drive_scope(actor => $actor, drive => {params => ['data'], body => []});
    is_deeply($scope->{data}, {role => 'local', type_spec => undef}, 'parameter masks actor role as well as type');
};

subtest 'scopes add no inferred declarations and detach from actor facts' => sub {
    my $before = $json->encode($actor);
    my $tx = dclone($actor->{transactions}[1]);
    push @{$tx->{clauses}}, ['set', 'data', 0], ['set', 'invented', 1];
    my $scope = record_transaction_scope(actor => $actor, transaction => $tx);
    is($scope->{data}{role}, 'input', 'assignment does not redefine actor input');
    ok(!exists($scope->{invented}), 'assignment target is not a declaration');
    $scope->{packet}{type_spec}{members}{payload}{width} = 999;
    $scope->{data}{role} = 'local';
    is($json->encode($actor), $before, 'mutating projection leaves complete actor unchanged');
    is(record_actor_scope(actor => $actor)->{packet}{type_spec}{members}{payload}{width}, 6,
        'fresh projection does not reuse mutated output');
};

subtest 'imported alias and prepared record pin keep actual resolved facts' => sub {
    my $work = tempdir(CLEANUP => 1);
    open my $file, '>', "$work/shared.fsm" or die $!;
    print {$file} '(?pkg:shared (+types (type frame (record (header (bits 2)) '
        . '(payload (signed (four_state (bits 6))))))))';
    close $file or die $!;
    my $imported = $parser->parse_source('(actor imported (imports (package shared))'
        . ' (interface (output done)) (storage (var value (type shared.frame)))'
        . ' (transaction main (complete done)))', "$work/imported.isf");
    is_deeply(record_actor_scope(actor => $imported)->{value}{type_spec},
        record_actor_scope(actor => $actor)->{packet}{type_spec}, 'local and imported resolved identity matches');
    my $prepared = dclone($imported);
    $prepared->{interface}{inputs} = [dclone($prepared->{storage}[0])];
    my $scope = record_actor_scope(actor => $prepared);
    is($scope->{value}{role}, 'input', 'supplied resolved record declaration retains input role');
    refuses(sub {reference($scope, 'value.payload', 'write')}, qr/cannot write declared input 'value.payload'/,
        'prepared input leaf cannot become a write');
    refuses(sub {$parser->parse_source('(actor refused (types (type frame (record (x bit))))'
        . ' (interface (input value (type frame)) (output done))'
        . ' (transaction main (complete done)))', 'still-refused.isf')},
        qr/interface port 'value' references aggregate type/, 'authored record input stays refused');
};

subtest 'scope preparation leaves complete parser and scheduled products unchanged' => sub {
    my $safe = $parser->parse_source($source, 'scope-controls.isf');
    my $before_actor = $json->encode($safe);
    my $before_lowered = $json->encode(FSM::Scheduler::ISF->new->lower(dclone($safe)));
    record_actor_scope(actor => $safe);
    record_transaction_scope(actor => $safe, transaction => $_) for @{$safe->{transactions}};
    record_drive_scope(actor => $safe, drive => $_) for values %{$safe->{drives}};
    is($json->encode($safe), $before_actor, 'complete parsed actor unchanged');
    is($json->encode(FSM::Scheduler::ISF->new->lower(dclone($safe))), $before_lowered,
        'complete scheduled object and actual emitted file bytes unchanged');
};

subtest 'malformed declaration facts fail without accidental fallback' => sub {
    my $bad = dclone($actor);
    $bad->{interface}{outputs}[0]{name} = 'start';
    refuses(sub {record_actor_scope(actor => $bad)}, qr/duplicate port 'start'/, 'duplicate interface role');
    $bad = dclone($actor);
    $bad->{storage}[0]{width} = 9;
    refuses(sub {record_actor_scope(actor => $bad)}, qr/resolved type disagrees with declared width/,
        'mismatched declared packed width');
    refuses(sub {record_drive_scope(actor => $actor, drive => {params => ['bad.name']})},
        qr/drive parameter requires an identifier/, 'invalid parameter root');
    refuses(sub {record_actor_scope(actor => $actor, extra => 1)}, qr/unknown scope argument/,
        'closed helper arguments');
};

done_testing;
