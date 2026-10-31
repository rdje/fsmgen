use strict;
use warnings;
no warnings 'once';
use lib 'perl';
use Test::More;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use Scalar::Util qw(weaken);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;

my $factor = 'FSM::Synthesis::EnableGraph::FactorizationSupport';
my $normal = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport';
my $normalize = $normal->can('normalize_consolidated_intermediate_metadata');
my $metadata = $normal->can('_normalize_metadata');
my $prime = $factor->can('prime_intermediate_signal_live_usage');
my $resolve = $factor->can('resolve_intermediate_signal_live_usage');
my $json = JSON::PP->new->canonical;
for my $path ('FSM/Synthesis/EnableGraph/FactorizationSupport.pm',
    'FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateNormalizationSupport.pm') {
    is($INC{$path}, "perl/$path", 'actual native normalization owner loaded');
    open my $source, '<', $INC{$path} or die $!;
    binmode $source;
    local $/;
    note("loaded $INC{$path} sha256=" . sha256_hex(<$source>));
}

sub fixture {
    my ($mutable) = @_;
    my $params = $mutable ? '(+params (W 8))' : '';
    my $width = $mutable ? '(param W)' : 8;
    my $source = "(?fsm:normalization $params (+size (A $width) (B 3) (DATA 1) (OTHER 1))"
        . ' (idle (<(concat A B) (= (DATA 1))) (<(concat B A) (= (OTHER 1))) (-> idle)))';
    my $raw = scalar Lispish::multi(\$source);
    return (FSM::Adapter::FSMGenFull->new->parse_fsm($raw), $raw);
}

sub events {
    my ($owner, $rows, $names) = @_;
    return [map {scalar $owner->concatenation_inference_event($_, $rows->{$_})} @$names];
}

subtest 'bulk fallback and mixed writers join at both actual normalization exits' => sub {
    for my $route (qw(bulk fallback mixed)) {
        for my $mutable (0, 1) {
            for my $language (qw(systemverilog verilog)) {
                my ($module, $raw) = fixture($mutable);
                my $caller = $json->encode($raw);
                my $backend = FSM::HDL::FlattenedDT->new;
                my ($before, $weak_view, $owner, $inner, $outer, $context, @retained);
                my @names;
                my $expected_context = $route eq 'bulk' ? 'void' : $route eq 'fallback' ? 'scalar' : 'list';
                my $check = sub {
                    my ($rows) = @_;
                    is_deeply(events($owner, $rows, \@names), $before, 'same original records current at actual exit');
                    for my $name (@names) {
                        my $row = $rows->{$name};
                        is($row->{width}, 11, 'independent ordered sum remains numeric eleven');
                        is($row->{width_source}, 'substituted_ast', 'actual intrinsic width source preserves');
                        is($row->{rendered_expression}, $row->{ast}->to_systemverilog, 'actual typed rendering agrees');
                        is_deeply($row->{dependency_signal_names}, [], 'whole Core inputs introduce no intermediate-signal dependencies');
                        is($row->{dependency_source}, 'substituted_ast', 'original dependency source');
                        is($row->{live_usage_source}, 'ast_live_usage_metadata', 'actual usage annotation');
                        ok(exists($row->{referenced_in_substitutions}) && exists($row->{used_in_final_expressions}), 'both actual usage booleans installed');
                        is($owner->intermediate_width_allocation($name, $row), undef, 'normalization exit grants no completed policy');
                    }
                };
                {
                    no warnings 'redefine';
                    local *FSM::Synthesis::EnableGraph::FactorizationSupport::prime_intermediate_signal_live_usage = sub {
                        my ($support, $rows) = @_;
                        $owner = $backend->{backend_sv_intermediate_width_support};
                        @names = sort grep {ref($rows->{$_}{ast}) eq 'FSM::CoreAST::Concatenation'} keys %$rows;
                        is(scalar @names, 2, 'two actual prepared rows');
                        $before = events($owner, $rows, \@names);
                        ok($before->[0] && $before->[1], 'original records current before selected writers');
                        $weak_view = $rows; weaken($weak_view);
                        push @retained, $rows->{$_} for @names;
                        return {} if $route eq 'fallback';
                        $resolve->($support, $names[0], $rows->{$names[0]}) if $route eq 'mixed';
                        return $prime->(@_);
                    };
                    local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport::_normalize_metadata = sub {
                        $context = !defined(wantarray) ? 'void' : wantarray ? 'list' : 'scalar';
                        my $want = wantarray;
                        my (@result, $result);
                        if (!defined $want) {$metadata->(@_)}
                        elsif ($want) {@result = $metadata->(@_)}
                        else {$result = $metadata->(@_)}
                        $check->($_[1]); $inner++;
                        return $want ? @result : $result;
                    };
                    local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport::normalize_consolidated_intermediate_metadata = sub {
                        if ($expected_context eq 'void') {$normalize->(@_)}
                        elsif ($expected_context eq 'list') {my @result = $normalize->(@_)}
                        else {my $result = $normalize->(@_)}
                        is($context, $expected_context, 'wrapper preserves selected native call context');
                        $check->($_[1]); $outer++;
                    };
                    my $ok = eval {$language eq 'verilog' ? $backend->generate_verilog($module) : $backend->generate_systemverilog($module); 1};
                    is($ok ? 1 : 0, $mutable ? 0 : 1, 'fixed generation and mutable symbolic refusal preserve') or diag $@;
                }
                is($inner, 1, 'actual metadata exit observed');
                is($outer, 1, 'actual public normalization exit observed');
                is($json->encode($raw), $caller, 'complete caller preserves');
                ok(!defined($weak_view), 'retained rows and records do not keep weak view alive');
            }
        }
    }
};

subtest 'late cached callbacks withhold changed events and wrapper failure clears partial authority' => sub {
    for my $mode (qw(row source missing throwing)) {
        my ($module) = fixture(0);
        my $backend = FSM::HDL::FlattenedDT->new;
        my ($rows, $owner, $before, $calls, $seen, @names);
        {
            no warnings 'redefine';
            local *FSM::Synthesis::EnableGraph::FactorizationSupport::prime_intermediate_signal_live_usage = sub {
                $rows = $_[1];
                $owner = $backend->{backend_sv_intermediate_width_support};
                @names = sort grep {ref($rows->{$_}{ast}) eq 'FSM::CoreAST::Concatenation'} keys %$rows;
                my $result = $prime->(@_);
                $before = events($owner, $rows, \@names);
                ok($before->[0] && $before->[1], 'actual priming arrives current');
                return $result;
            };
            local *FSM::Synthesis::EnableGraph::FactorizationSupport::resolve_intermediate_signal_live_usage = sub {
                my $result = $resolve->(@_);
                if (++$calls == keys %$rows) {
                    $rows->{$names[0]}{hostile} = 1 if $mode eq 'row';
                    $module->{signals}{A}{signed} = 1 if $mode eq 'source';
                    delete $owner->{_concatenation_inference_events}{$names[0]} if $mode eq 'missing';
                    die "normalization join failure\n" if $mode eq 'throwing';
                }
                return $result;
            };
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport::normalize_consolidated_intermediate_metadata = sub {
                my $ok = eval {$normalize->(@_); 1};
                if ($mode eq 'throwing') {
                    ok(!$ok, 'actual wrapper rethrows original failure');
                    like($@, qr/normalization join failure/, 'original error preserves');
                    is_deeply($owner->{_concatenation_inference_events}, {}, 'abort clears every partial holder');
                } else {
                    ok($ok, 'ordinary normalization returns') or diag $@;
                    is($owner->concatenation_inference_event($names[0], $rows->{$names[0]}), undef, 'changed or missing proof withholds at actual exit');
                    is($owner->intermediate_width_allocation($names[0], $rows->{$names[0]}), undef, 'no completed policy');
                }
                $seen++;
            };
            eval {$backend->generate_systemverilog($module)};
        }
        is($seen, 1, "$mode actual normalization exit observed");
        delete $rows->{$names[0]}{hostile};
        $module->{signals}{A}{signed} = 0;
        my $recovered;
        {
            no warnings 'redefine';
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport::normalize_consolidated_intermediate_metadata = sub {
                $normalize->(@_);
                my $current = $backend->{backend_sv_intermediate_width_support};
                my @actual = sort grep {ref($_[1]{$_}{ast}) eq 'FSM::CoreAST::Concatenation'} keys %{$_[1]};
                ok(!grep(!defined($_), @{events($current, $_[1], \@actual)}), 'fresh generation has its own current events');
                $recovered++;
            };
            ok(eval {$backend->generate_systemverilog($module); 1}, 'same backend clean generation succeeds') or diag $@;
        }
        is($recovered, 1, 'fresh actual normalization exit observed');
    }
};

done_testing();
