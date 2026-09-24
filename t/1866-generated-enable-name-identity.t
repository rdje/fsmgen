#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Pipeline::HDLGenerator;
use FSM::Pipeline::SourceFrontend;
use FSM::HDL::FlattenedDT;

my $work = tempdir(CLEANUP => 1);

sub source_file {
    my ($name, $sizes, $body) = @_;
    my $path = File::Spec->catfile($work, "$name.fsm");
    open my $fh, '>', $path or die "$path: $!";
    print {$fh} "(?fsm:$name\n (+system (clock clk) (sreset reset))\n"
        . " (+size $sizes)\n $body\n)\n" or die "$path: $!";
    close $fh or die "$path: $!";
    return $path;
}

sub check_wiring {
    my ($path, $expectations, $reserved) = @_;
    my $result = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0, target_language => 'systemverilog', quiet => 1,
    )->generate_hdl_from_file($path);
    my @records = grep {
        ($_->{provenance}{family} // '') eq 'generated_enable'
    } @{$result->{structural_rtl_ir}{assignment_records}};
    my %seen;
    for my $r (@records) {
        my $name = $r->{lhs}{name};
        ok(!$seen{$name}++, "one generated driver for $name");
        my $role = $r->{provenance}{role};
        next unless $role eq 'dt_specific_enable' || $role eq 'lhs_level_enable';
        ok(!$reserved->{$name}, "$role does not shadow authored/reserved $name");
        like($result->{hdl_code}, qr/\Q$r->{rendered}\E/,
            "$name semantic record matches emitted HDL");
    }
    for my $e (@$expectations) {
        my ($lhs, $rhs, $dt, $condition) = @$e;
        my @local = grep {
            $_->{provenance}{role} eq 'dt_specific_enable'
                && $_->{provenance}{lhs_signal} eq $lhs
                && $_->{provenance}{rhs_value} eq $rhs
                && $_->{provenance}{dt_name} eq $dt
        } @records;
        my @group = grep {
            $_->{provenance}{role} eq 'lhs_level_enable'
                && $_->{provenance}{lhs_signal} eq $lhs
                && $_->{provenance}{rhs_value} eq $rhs
        } @records;
        is(scalar @local, 1, "$lhs <- $rhs retains its original $dt driver");
        is(scalar @group, 1, "$lhs <- $rhs has one group enable");
        next unless @local == 1 && @group == 1;
        like($local[0]{rhs}{text}, qr/\b\Q$condition\E\b/,
            "$lhs <- $rhs retains original condition $condition after factorization");
        is($group[0]{rhs}{text}, $local[0]{lhs}{name},
            "$lhs <- $rhs refers to its own DT-local enable");
    }
    return $result;
}

subtest 'case-distinct outputs in one DT keep independent conditions' => sub {
    my $path = 't/fixtures/generated_enable_name_identity/independent_outputs.fsm';
    my $result = check_wiring($path,
        [['OUT', '1', 'idle', 'UP'], ['out', '1', 'idle', 'DOWN']], {});
    my %names = map { $_->{provenance}{lhs_signal} => $_->{lhs}{name} }
        grep { ($_->{provenance}{role} // '') eq 'lhs_level_enable' }
        @{$result->{structural_rtl_ir}{assignment_records}};
    is_deeply(\%names, {OUT => 'out_1_en', out => 'out_1_2_en'},
        'case-sensitive lexical order fixes readable name allocation');
};

subtest 'different DTs and repeated cleaning separators retain signal identity' => sub {
    my $path = source_file('enable_separate_dt',
        '(OUT 1) (out 1) (a_b 1) (a__b 1) (UP 1) (DOWN 1)',
        '(idle (-> first))'
        . '(first (<UP (OUT <- 1) (a_b <- 0)) (-> second))'
        . '(second (<DOWN (out <- 1) (a__b <- 0)) (-> first))');
    check_wiring($path, [
        ['OUT', '1', 'first', 'UP'], ['out', '1', 'second', 'DOWN'],
        ['a_b', '0', 'first', 'UP'], ['a__b', '0', 'second', 'DOWN'],
    ], {});
};

subtest 'same-DT case-distinct RHSs keep separate write selection' => sub {
    my $path = source_file('enable_rhs_identity',
        '(OUT 8) (DATA 8) (data 8) (UP 1) (DOWN 1)',
        '(idle (<UP (OUT <- DATA)) (<DOWN (OUT <- data)))');
    check_wiring($path, [
        ['OUT', 'DATA', 'idle', 'UP'], ['OUT', 'data', 'idle', 'DOWN'],
    ], {});
};

subtest 'DT and LHS families share a namespace and skip occupied suffixes' => sub {
    my $path = source_file('enable_family_identity',
        '(foo 1) (first_foo 1) (foo_0_en 1) (foo_0_2_en 1) (observed 1) (UP 1) (DOWN 1)',
        '(idle (<DOWN (first_foo <- 0)) (observed = (& foo_0_en foo_0_2_en)) (-> first))'
        . '(first (<UP (foo <- 0)) (-> idle))');
    check_wiring($path, [
        ['foo', '0', 'first', 'UP'], ['first_foo', '0', 'idle', 'DOWN'],
    ], {foo_0_en => 1, foo_0_2_en => 1});
};

subtest 'top-level enables stay reserved and repeated analysis is stable' => sub {
    my $path = source_file('enable_rebuild_identity',
        '(OUT 1) (out 1) (UP 1) (DOWN 1)',
        '(out_1 (<UP (OUT <- 1)) (<DOWN (out <- 1)))');
    check_wiring($path, [['OUT', '1', 'out_1', 'UP'], ['out', '1', 'out_1', 'DOWN']],
        {out_1_en => 1});
    my $ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(fsm_file => $path, debug_level => 0);
    my $module = FSM::Pipeline::SourceFrontend->create_fsm_module(raw_ast => $ast, debug_level => 0);
    my $backend = FSM::HDL::FlattenedDT->new(debug => 0);
    $backend->{orchestrator}->reset_generation_state();
    $backend->{enable_graph_signal_support}->set_fsm_module_reference($module);
    $backend->{orchestrator}->flatten_all_decision_trees($module);
    my $snapshot = sub {
        return [map {
            my $lhs = $_;
            map {
                my $group = $backend->{assignment_analysis}{$lhs}{rhs_groups}{$_};
                [$lhs, $_, $group->{lhs_level_enable}{name},
                    map { $_->{enable_name} } @{$group->{dt_specific_enables}}]
            } sort keys %{$backend->{assignment_analysis}{$lhs}{rhs_groups}}
        } sort keys %{$backend->{assignment_analysis}}];
    };
    my $before = $snapshot->();
    $backend->{enable_graph_assignment_support}->build_unified_assignment_analysis($module);
    is_deeply($snapshot->(), $before, 'rebuild starts a fresh allocation scope');
};

subtest 'system ports and parameters reserve generated enable candidates' => sub {
    my $path = source_file('enable_system_identity', '(OUT 1) (UP 1)',
        '(idle (<UP (<- (OUT> 1))))');
    open my $in, '<', $path or die "$path: $!";
    my $source = do { local $/; <$in> };
    close $in or die "$path: $!";
    $source =~ s/\(clock clk\)/(clock out_1_en)/;
    $source =~ s/\(sreset reset\)/(sreset out_1_2_en)/;
    $source =~ s/\(\+size/(+params (out_1_3_en 1))\n (+size/;
    open my $fh, '>', $path or die "$path: $!";
    print {$fh} $source or die "$path: $!";
    close $fh or die "$path: $!";
    check_wiring($path, [['OUT', '1', 'idle', 'UP']],
        {out_1_en => 1, out_1_2_en => 1, out_1_3_en => 1});
};

done_testing();
