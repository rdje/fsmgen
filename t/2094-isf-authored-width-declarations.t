use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use File::Temp qw(tempdir);
use JSON::PP;
use FSM::Test::ProjectDataLocality;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $json = JSON::PP->new->canonical;
my $work = tempdir(CLEANUP => 1);
write_file("$work/shared.fsm", '(?pkg:shared (+constants (WIDTH 8)))');

my $source = <<'ISF';
(actor authored_widths
  (clock clk) (reset rst_n)
  (imports (package shared))
  (params (WIDTH 8) (ALIAS WIDTH) (OTHER 8))
  (constants (FIXED 8))
  (types (type byte_t (bits 8)))
  (interface (input start) (input data (width WIDTH))
    (input alias_data (width ALIAS)) (input other_data (width OTHER))
    (input fixed_data (width FIXED)) (input package_data (width shared.WIDTH))
    (input literal_data (width 8)) (input typed_data (type byte_t))
    (output result (width WIDTH)))
  (storage (var saved (width ALIAS) (reset 3))
    (bank words (width OTHER) (depth 2))
    (variable fixed_saved (width FIXED))
    (bank package_words (width shared.WIDTH) (depth 1)))
  (transaction main (on start) (set result data)))
ISF

subtest 'equal resolved widths retain distinct authored declarations' => sub {
    my $actor = parse_source($source, 'actor');
    my %ports = map {$_->{name} => $_}
        @{$actor->{interface}{inputs}}, @{$actor->{interface}{outputs}};
    for my $case (
        ['data', 'WIDTH', 'actor_parameter', 'authored_widths'],
        ['alias_data', 'ALIAS', 'actor_parameter', 'authored_widths'],
        ['other_data', 'OTHER', 'actor_parameter', 'authored_widths'],
        ['fixed_data', 'FIXED', 'actor_constant', 'authored_widths'],
        ['package_data', 'shared.WIDTH', 'package_constant', 'shared'],
        ['result', 'WIDTH', 'actor_parameter', 'authored_widths'],
    ) {
        my ($name, $token, $kind, $owner) = @$case;
        is($ports{$name}{width}, 8, "$name keeps its resolved default");
        is_deeply($ports{$name}{_width_declaration},
            {token => $token, kind => $kind, owner => $owner},
            "$name retains its actual token, namespace and lexical owner");
    }
    for my $name (qw(start literal_data typed_data)) {
        ok(!exists $ports{$name}{_width_declaration}, "$name gains no invented dependency");
    }
    is($ports{typed_data}{type}, 'byte_t', 'named type keeps its existing reference');
    is_deeply($actor->{params}[1],
        {name => 'ALIAS', value => 'WIDTH', resolved_value => '8'},
        'alias keeps authored dependency and resolved value separately');
    for my $case (
        ['saved', 'ALIAS', 'actor_parameter', 'authored_widths'],
        ['words', 'OTHER', 'actor_parameter', 'authored_widths'],
        ['fixed_saved', 'FIXED', 'actor_constant', 'authored_widths'],
        ['package_words', 'shared.WIDTH', 'package_constant', 'shared'],
    ) {
        my ($name, $token, $kind, $owner) = @$case;
        my ($storage) = grep {$_->{name} eq $name} @{$actor->{storage}};
        is_deeply($storage->{_width_declaration},
            {token => $token, kind => $kind, owner => $owner},
            "$name storage retains its declaration rather than equal-width inference");
        is($storage->{width}, 8, "$name retains resolved width");
    }
    is($actor->{storage}[0]{reset_value}, 3, 'reset metadata stays unchanged');
    is_deeply([map {$_->{width}} @{$actor->{storage}[1]{signals}}], [8, 8],
        'bank element widths remain resolved');

    my $before = $json->encode($actor);
    my $scheduler = FSM::Scheduler::ISF->new;
    my $lowered = $scheduler->lower($actor);
    is($json->encode($actor), $before, 'lowering preserves complete caller and JSON kinds');
    my $fsm = $lowered->{files}{'authored_widths.fsm'};
    like($fsm, qr/\(data 8\)/, 'carrier remains resolved in parser preparation');
    unlike($fsm, qr/_width_declaration/, 'private record does not leak into IAL0');
    my $report = $scheduler->report($actor);
    unlike($report, qr/_width_declaration/, 'private record does not leak into schedule JSON');
};

subtest 'nearest transaction parameters retain their own lexical identity' => sub {
    my $actor = parse_source(<<'ISF', 'transaction');
(actor lexical_widths
  (clock clk) (params (WIDTH 16) (OTHER 8)) (constants (FIXED 8))
  (imports (package shared))
  (interface (input start) (input data (width 8)) (output result (width 8)))
  (transaction main (on start) (params (WIDTH 4) (ALIAS WIDTH))
    (ports (input local_data (width WIDTH)) (input alias_data (width ALIAS))
      (input inherited_data (width OTHER)) (input constant_data (width FIXED))
      (input package_data (width shared.WIDTH)) (input literal_data (width 4)))
    (set result data)))
ISF
    my @ports = @{$actor->{transactions}[0]{ports}{inputs}};
    my @expected = (
        ['WIDTH', 'transaction_parameter', 'main', 4],
        ['ALIAS', 'transaction_parameter', 'main', 4],
        ['OTHER', 'actor_parameter', 'lexical_widths', 8],
        ['FIXED', 'actor_constant', 'lexical_widths', 8],
        ['shared.WIDTH', 'package_constant', 'shared', 8],
    );
    for my $index (0 .. $#expected) {
        my ($token, $kind, $owner, $width) = @{$expected[$index]};
        is($ports[$index]{width}, $width, "$token resolves in its real scope");
        is_deeply($ports[$index]{_width_declaration},
            {token => $token, kind => $kind, owner => $owner},
            "$token preserves scope rather than borrowing an equal actor default");
    }
    ok(!exists $ports[-1]{_width_declaration}, 'literal formal gains no dependency');
};

subtest 'library clones retain source owners and independent records' => sub {
    my $actor = parse_source(<<'ISF', 'library');
(library widths (exports (actor child))
  (actor child (clock clk) (params (WIDTH 8))
    (interface (input data (width WIDTH)) (output result (width WIDTH)))
    (rule copy 1 (result data))))
(actor clone_widths (clock clk)
  (imports (library widths as lib))
  (interface (input data (width 8)) (output result (width 8)) (output other (width 8)))
  (use lib.child as first (params (WIDTH 16))
    (bind (clock clk) (input data data) (output result result)))
  (use lib.child as second
    (bind (clock clk) (input data data) (output result other))))
ISF
    my @ports = map {$_->{actor}{interface}{inputs}[0]} @{$actor->{library_uses}};
    for my $port (@ports) {
        is_deeply($port->{_width_declaration},
            {token => 'WIDTH', kind => 'actor_parameter', owner => 'child'},
            'clone keeps original lexical declaration owner');
        is($port->{width}, 8, 'private preservation does not implement specialization');
    }
    is_deeply($actor->{library_uses}[0]{parameter_overrides}, [{name => 'WIDTH', value => '16'}],
        'existing explicit override remains distinct from resolved source shape');
    # A returned clone record must not share its mutable association with its
    # sibling. Missing records already fail the literal assertions above.
    if (ref($ports[0]{_width_declaration}) eq 'HASH') {
        $ports[0]{_width_declaration}{token} = 'OTHER';
        is($ports[1]{_width_declaration}{token}, 'WIDTH', 'sibling association is detached');
    }
};

done_testing;

sub parse_source {
    my ($text, $name) = @_;
    my $path = "$work/$name.isf";
    write_file($path, $text);
    return FSM::Adapter::ISF->new->parse_file($path);
}

sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>:raw', $path or die $!;
    print {$fh} $text or die $!;
    close $fh or die $!;
}
