#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Test::More;
use lib "$FindBin::Bin/../perl";
use FSM::VIAL::Parser;
use FSM::VIAL::SourceProjection;
use FSM::VIAL::SourceInspection;

my $json = JSON::PP->new->canonical;
my $package = 'ahb_subordinate_base_output_arbitration';
my $fixture_id = "$package\::fixture::base_output_arbitration";
my %base = map { $_ => read_file('vial/ahb_subordinate_base_output_arbitration'
    . ($_ == 2 ? '_v2' : '') . '.vial') } (1, 2);
sub rich_source {
    my ($version) = @_;
    my $s = $base{$version};
    $s =~ s/\(types/\(types (type pair (record (left (u 8)) (right bool))) (type vector (list 3 (type pair))) (type signed_logic (slogic 4))/;
    $s =~ s/\(state \(count \(u 32\) 0\)\)/(state (count (u 32) 0) (signed_count (s 8) -3))/;
    $s =~ s/\(set count \(\+ count 1\)\)/(set count (+ count 1)) (set signed_count (- signed_count 1))/;
    $s =~ s/\(endpoints/\(endpoints (endpoint record_in "endpoint\/record_in" (type pair) public_port)/;
    $s =~ s/\(policy in_order\)/(policy keyed) (key address)/;
    $s =~ s/\(value_eq \(event_count success_write accepted\) 1\)/(value_eq (model accepts count) 1)/;
    $s =~ s/\(reset bus 3\)/(reset bus 3) (drive ready_out #b1) (repeat 2 (drive ready_out #b0))
      (expect field_value (value_eq (field (sample record_in) left) 1))
      (expect four_state (same (sample ready_out) #bz))
      (expect implications (=> (and true (or false (xor true false))) (next true)))
      (expect comparisons (and (not false) (known (sample response))
        (>= (choice success_wait) 1) (<= (choice success_wait) 2)
        (> (choice success_wait) 0) (< (choice success_wait) 3)))/;
    $s =~ s/\(coverage/\(coverage
      (coverpoint counts (sample bus) (expr (event_count write accepted))
        (bins (bin low normal (range 0 2)) (bin high ignore (range 3 4))))
      (cross combined (points counts stall_seen) (max_bins 4))/;
    return $s;
}
sub parse { FSM::VIAL::Parser->parse_source({text => $_[0], source_name => 'inspect.vial', source_catalog => $_[1] // {}}) }
sub inspect { FSM::VIAL::SourceInspection->build(parse(@_)) }
sub strip_locations {
    my ($x) = @_;
    return $x unless ref $x;
    return [map { strip_locations($_) } @$x] if ref($x) eq 'ARRAY';
    return $x if JSON::PP::is_bool($x);
    return {map { $_ => strip_locations($x->{$_}) } grep { $_ ne 'source_location' } keys %$x};
}
sub walk {
    my ($x, $predicate) = @_;
    return () unless ref($x);
    return map { walk($_, $predicate) } @$x if ref($x) eq 'ARRAY';
    return () unless ref($x) eq 'HASH';
    return (($predicate->($x) ? ($x) : ()), map { walk($x->{$_}, $predicate) } sort keys %$x);
}

for my $version (1, 2) {
    subtest "v$version complete base details retain authored meaning" => sub {
        my $text = rich_source($version);
        my $ir = parse($text);
        my $before = $json->encode($ir->as_hashref);
        my $r = FSM::VIAL::SourceInspection->build($ir);
        is_deeply([sort keys %$r], [sort qw(schema schema_version language language_version profile root_source sources packages required_capabilities unresolved_bridge_refs)], 'closed independent detail envelope');
        is($r->{schema}, 'fsmgen.vial_source_semantics.v1', 'public schema independent from source version');
        is($r->{language_version}, $version, 'explicit source version preserved');
        is($r->{root_source}{content_sha256}, sha256_hex($text), 'root identity covers actual source bytes');
        is($r->{root_source}{byte_length}, length($text), 'root byte length preserved');
        my $p = $r->{packages}[0]; my $f = $p->{fixtures}[0];
        is_deeply($p->{intent_families}, [], 'base sources explicitly contain no intent families');
        my %types = map { $_->{name} => $_->{type} } @{$p->{types}};
        is($types{vector}{length}, 3, 'bounded list length is inspectable');
        is($types{vector}{element_type}{resolved}{fields}[0]{type}{width}, 8, 'nested record field width is inspectable');
        ok(JSON::PP::is_bool($types{signed_logic}{signed}) && $types{signed_logic}{signed}, 'type flags are public JSON booleans');
        is($p->{models}[0]{state}[1]{initial_value}{value_decimal}, '-3', 'signed initial state is preserved as decimal text');
        is($p->{models}[0]{rules}[0]{assignments}[1]{expression}{op}, '-', 'complete model update body preserved');
        is_deeply([map { $_->{name} } @{$types{htrans_t}{members}}], [qw(idle nonseq)], 'enum member order retained');
        is($types{htrans_t}{members}[1]{value}{value_bits}, '2', 'enum encoding retained');
        is($p->{models}[0]{inputs}[0]{type}{kind}, 'event', 'event model input retained');
        is($f->{instances}{model_instances}[0]{bindings}[0]{value}{event_id},
            "$package\::transaction::ahb_write::event::accepted", 'model input binds the authored transaction event');
        is($p->{scoreboards}[0]{key}, 'address', 'keyed scoreboard field retained');
        is($p->{scoreboards}[0]{capacity}, 4, 'scoreboard bound retained');
        my @model = walk($r, sub { ($_[0]{op} // '') eq 'model' });
        is($model[0]{model_instance_id}, "$fixture_id\::model_instance::accepts", 'model read keeps selected instance');
        is($f->{faults}[0]{transaction_binding_id}, "$fixture_id\::transaction_binding::write", 'public fault target always resolves the unique binding');
        is($f->{faults}[0]{substitute}{value}{value_bits}, '7', 'fault substitute bits preserved');
        is($f->{randomness}{seed}, '1', 'authored seed retained without evaluating it');
        is($f->{randomness}{choices}[0]{decision_id}, 'success.wait_cycles', 'authored decision identity retained');
        ok(!exists($f->{randomness}{decisions}), 'inspection invents no evaluated random decisions');
        is($f->{coverage}{coverpoints}[0]{bins}[1]{matcher}{high}{value_decimal}, '4', 'range matcher bound retained');
        is_deeply($f->{coverage}{crosses}[0]{point_ids}, [map { "$fixture_id\::coverpoint::$_" } qw(counts stall_seen)], 'ordered cross references retained');
        my @actions = @{$f->{scenarios}[0]{actions}};
        my %actions = map { $_->{kind} => 1 } walk($f->{scenarios}, sub {
            exists($_[0]{kind}) && exists($_[0]{source_location}) && !exists($_[0]{result_type}) });
        ok($actions{$_}, "action $_ has inspectable detail") for qw(reset drive start await parallel repeat expect scoreboard_expect scoreboard_check inject);
        is_deeply([map { $_->{kind} } @actions[0..2]], [qw(reset drive repeat)], 'authored action order retained');
        is($actions[2]{count}, 2, 'repeat bound retained without expansion');
        is($actions[2]{actions}[0]{kind}, 'drive', 'nested repeat action retained');
        my %ops = map { $_->{op} => 1 } walk($r, sub { exists $_[0]{op} });
        ok($ops{$_}, "operator/reference $_ has a complete record") for qw(field not and or xor same value_eq known + - < <= > >= model choice sample event event_count next within), '=>';
        my @z = walk($r, sub { ($_[0]{kind} // '') eq 'logic_vector' && ($_[0]{z_mask} // '') eq '1' });
        ok(@z, 'four-state Z mask remains distinct from value bits');
        my $loc = $actions[1]{source_location};
        is(substr($text, $loc->{start_byte}, $loc->{end_byte_exclusive} - $loc->{start_byte}), '(drive ready_out #b1)', 'public coordinates independently select exact authored action');
        is($loc->{source_name}, 'inspect.vial', 'coordinates retain relative source identity');
        is($r->{unresolved_bridge_refs}[0]{kind}, 'unit', 'bridge assertions retain deterministic category order');
        ok(grep({ $_->{bridge_ref} eq 'endpoint/record_in' } @{$r->{unresolved_bridge_refs}}), 'unbound authored endpoint remains inspectable');
        unlike($json->encode($r), qr/"(?:provenance|source_span|plan_id)":/, 'no compiler provenance table or execution identity leaks');
        is($json->encode($ir->as_hashref), $before, 'compiler input is untouched');
        is_deeply(FSM::VIAL::SourceInspection->build($ir), $r, 'repeated projection is deterministic');
        my $terse = FSM::VIAL::SourceProjection->format_source({text => $text, source_name => 'inspect.vial', output_style => 'terse'})->{text};
        is_deeply(strip_locations(inspect($terse)->{packages}), strip_locations($r->{packages}), 'style changes preserve all meaning fields');
        $r->{packages}[0]{models}[0]{state}[0]{name} = 'mutated';
        is(FSM::VIAL::SourceInspection->build($ir)->{packages}[0]{models}[0]{state}[0]{name}, 'count', 'caller mutations cannot affect later results');
    };
}

subtest 'imports and explicit ambiguous fault selection remain resolved' => sub {
    for my $version (1, 2) {
        my $library = $base{$version}; $library =~ s/package \Q$package\E/package library/;
        my $text = $base{$version};
        $text =~ s/\(imports\)/(imports (import lib "library.vial"))/;
        $text =~ s/\(types/\(types (type shared_t (type lib.address_t))/;
        $text =~ s/\(transaction write "transaction\/ahb_write" ahb_write\)/(transaction write "transaction\/ahb_write" ahb_write) (transaction other "transaction\/other" ahb_write)/;
        $text =~ s/\(target \(transaction write size\)\)/(target (transaction other size))/;
        my $r = inspect($text, {'library.vial' => $library});
        is_deeply([map { $_->{source_name} } @{$r->{sources}}], ['inspect.vial', 'library.vial'], 'connected source identities stay ordered');
        is($r->{packages}[0]{imports}[0]{package_id}, 'library::package::library', 'import resolves to explicit package identity');
        is($r->{packages}[0]{types}[0]{type}{semantic_id}, 'library::type::address_t', 'qualified type resolves through import');
        is($r->{packages}[0]{fixtures}[0]{faults}[0]{transaction_binding_id}, "$fixture_id\::transaction_binding::other", 'explicit ambiguous fault scope is preserved');
    }
};

subtest 'forward type references retain authored declaration order' => sub {
    for my $version (1, 2) {
        my $text = $base{$version};
        $text =~ s/\(types/(types (type first (type later)) (type later (u 8))/;
        my $r = inspect($text);
        is_deeply([map { $_->{name} } @{$r->{packages}[0]{types}}],
            [qw(first later htrans_t address_t data_t)], 'authored order survives dependency-first construction');
        is($r->{packages}[0]{types}[0]{type}{semantic_id}, "$package\::type::later",
            'forward reference remains resolved after projection ordering');
    }
};

subtest 'schema drift and ambiguous missing scope fail closed' => sub {
    my $ir = parse(rich_source(1)); my $raw = $ir->as_hashref;
    my @cases = (
        ['unknown root', sub { $_[0]{secret_private} = 1 }, qr/unknown field/],
        ['missing field', sub { delete $_[0]{packages}[0]{models}[0]{state}[0]{initial_value} }, qr/missing field/],
        ['invalid coordinate', sub { $_[0]{packages}[0]{source_span}{start_byte} = 'unknown' }, qr/expected nonnegative integer/],
        ['unknown action', sub { $_[0]{packages}[0]{fixtures}[0]{scenarios}[0]{actions}[0]{kind} = 'new_action' }, qr/unknown action kind/],
        ['unknown operator', sub { $_[0]{packages}[0]{models}[0]{rules}[0]{assignments}[0]{expression}{op} = 'new_op' }, qr/unknown discriminant/],
        ['missing model scope', sub { my @r = walk($_[0], sub { ($_[0]{op} // '') eq 'model' }); delete $r[0]{model_instance_id} }, qr/missing field/],
        ['fault cannot infer', sub { my $f=$_[0]{packages}[0]{fixtures}[0]; push @{$f->{dut}{transaction_bindings}}, {%{$f->{dut}{transaction_bindings}[0]}, semantic_id=>'other'} }, qr/exactly one fixture binding/],
        ['forged explicit fault', sub { $_[0]{packages}[0]{fixtures}[0]{faults}[0]{transaction_binding_id}='missing' }, qr/exactly one fixture binding/],
        ['private link leak', sub { $_[0]{packages}[0]{fixtures}[0]{instances}{model_instances}[0]{model}={} }, qr/unknown field/],
    );
    for my $case (@cases) {
        my $changed = $json->decode($json->encode($raw)); $case->[1]->($changed);
        my ($ok, $error);
        { no warnings qw(redefine once); local *FSM::VIAL::SemanticIR::as_hashref = sub { $changed };
          $ok=eval { FSM::VIAL::SourceInspection->build($ir); 1 }; $error=$@; }
        ok(!$ok, "$case->[0] is rejected"); like($error, $case->[2], 'failure names the violated projection shape');
    }

};

ok(!exists($INC{'FSM/VIAL/PlanBuilder.pm'}), 'source inspection never loads a planner');
ok(!exists($INC{'FSM/VIAL/Backend/Runner.pm'}), 'source inspection never loads a backend runner');
done_testing();
sub read_file { open my $fh, '<:raw', "$FindBin::Bin/../$_[0]" or die $!; local $/; my $s=<$fh>; close $fh or die $!; return $s; }
