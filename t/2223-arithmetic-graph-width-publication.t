use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;

my $json = JSON::PP->new->canonical;
my $width_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport';
my $normal_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport';
sub fixture {
    my ($expression, $width, %options) = @_;
    my $source = "(?fsm:graph_publication (+params (W $width))"
        . ' (+size (A (param W)) (B (param W)) (C (param W)) (D (param W)) (DATA 1) (OTHER 1))'
        . " (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$source));
    my $ctx = $options{ctx} // FSM::HDL::FlattenedDT->new;
    my $publish = $width_class->can('_with_factorized_width_publication');
    my $normalize = $normal_class->can('normalize_consolidated_intermediate_metadata');
    my (%observed, $error, $hdl);
    {
        no warnings 'redefine';
        no strict 'refs';
        local *{"${width_class}::_with_factorized_width_publication"} = sub {
            my ($owner, $name, $info, $write) = @_;
            my $before = $owner->factorized_graph_inference_event($name, $info);
            my $wrapped = sub {
                $write->();
                $options{after_write}->($owner, $name, $info) if $before
                    && $options{after_write} && !$observed{changed}++;
            };
            $publish->($owner, $name, $info, $wrapped);
            if ($before) {
                $observed{publications}{$name} = {before => $before,
                    after => scalar($owner->factorized_graph_inference_event($name, $info))};
            }
        };
        local *{"${normal_class}::normalize_consolidated_intermediate_metadata"} = sub {
            my ($normal, $rows) = @_;
            my $want = wantarray;
            my ($result, @result);
            if (!defined($want)) {$normalize->(@_)}
            elsif ($want) {@result = $normalize->(@_)}
            else {$result = $normalize->(@_)}
            my $owner = $ctx->{backend_sv_intermediate_width_support};
            for my $name (sort keys %$rows) {
                my $birth = $ctx->{ast_factorizer}->intermediate_width_graph_birth($name) or next;
                $observed{normalized}{$name} = scalar($owner->factorized_graph_inference_event($name, $rows->{$name}));
            }
            return $want ? @result : $result;
        };
        eval {$hdl = $ctx->generate_systemverilog($module); 1} or $error = $@;
    }
    return {observed => \%observed, error => $error, ctx => $ctx, hdl => $hdl};
}

subtest 'actual normalizer publications preserve current transitive graph events' => sub {
    for my $expression ('(+ A B C)', '(+ A (* B C))', '(+ A (* B (+ C D)))', '(+ (+ A B C) (+ B C D))') {
        for my $width (1, 8) {
            my $p = fixture($expression, $width);
            is($p->{error}, undef, 'ordinary generation succeeds');
            my $rows = $p->{observed}{publications};
            ok(ref($rows) eq 'HASH' && keys %$rows, 'actual graph publications were observed');
            for my $name (sort keys %{$rows // {}}) {
                is_deeply($rows->{$name}{after}, $rows->{$name}{before}, 'exact width/source writes preserve held intrinsic record');
                is_deeply($p->{observed}{normalized}{$name}, $rows->{$name}{before}, 'all transitive graph proofs remain current after normalization');
            }
        }
    }
};

subtest 'source constraints and unowned registry replacements cannot refresh proof' => sub {
    for my $change (
        sub {my $a = $_[0]{flattened_dt}{fsm_module}->signals->{A}; $a->set_attribute('width_declared', $a->get_attribute('width_declared'))},
        sub {$_[0]{flattened_dt}{ast_factorizer}{intermediate_signals}{$_[1]}{signed} = 1},
        sub {my $ctx = $_[0]{flattened_dt}; $ctx->{intermediate_signals}{$_[1]} = {%{$ctx->{intermediate_signals}{$_[1]}}}},
    ) {
        my $p = fixture('(+ A (* B C))', 8, after_write => $change);
        ok($p->{observed}{changed}, 'actual graph callback performs the unsupported change');
        my @rows = values %{$p->{observed}{publications}};
        is($rows[0]{after}, undef, 'matching width cannot refresh changed source/constraint/identity');
    }
};

subtest 'publication failure clears all graph holders and permits fresh reuse' => sub {
    my $p = fixture('(+ A (* B C))', 8, after_write => sub {die "graph publication controlled failure\n"});
    like($p->{error}, qr/graph publication controlled failure/, 'original publication failure propagates');
    my $owner = $p->{ctx}{backend_sv_intermediate_width_support};
    is_deeply($owner->{_graph_inference_events}, {}, 'failed normalizer clears partial graph holders');
    is($owner->_current_graph_inference_rows, undef, 'failed normalizer removes weak row view');
    my $retry = fixture('(+ A (* B C))', 8, ctx => $p->{ctx});
    is($retry->{error}, undef, 'fresh generation reuses the actual backend');
    ok(grep(defined($_), values %{$retry->{observed}{normalized}}), 'fresh current graph proof is available after normalization');
};
done_testing();
