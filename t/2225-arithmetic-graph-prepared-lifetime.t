use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr isweak);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
my $json = JSON::PP->new->canonical;
my $build_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePreparedBlockSupport';
my $render_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateRenderingSupport';
sub records {
    my ($owner, $rows) = @_;
    my %events;
    for my $name (sort keys %$rows) {
        my $r = $owner->factorized_graph_inference_event($name, $rows->{$name});
        $events{$name} = $r if $r;
    }
    return \%events;
}
sub fixture {
    my ($expression, $width, %options) = @_;
    my $source = "(?fsm:prepared_graph (+params (W $width))"
        . ' (+size (A (param W)) (B (param W)) (C (param W)) (D (param W)) (DATA 1) (OTHER 1))'
        . " (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $input = $source;
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$input));
    my $ctx = $options{ctx} // FSM::HDL::FlattenedDT->new;
    my $build = $build_class->can('build_prepared_consolidated_intermediate_block');
    my $render = $render_class->can('render_prepared_consolidated_intermediate_block');
    my (@observations, $escaped, $filtered, $hdl, $error);
    my $observe = sub {
        my ($phase, $block) = @_;
        my $owner = $ctx->{backend_sv_intermediate_width_support};
        my $view = $owner->_current_graph_inference_rows;
        my $all = $block->{all_intermediate_signals};
        my $selected = $block->{filtered_signals};
        push @observations, {phase => $phase,
            view_is_weak => isweak($owner->{_graph_inference_rows}) ? 1 : 0,
            view_is_original => ref($view) eq 'HASH' && refaddr($view) == refaddr($all) ? 1 : 0,
            filtered_is_distinct => refaddr($selected) != refaddr($all) ? 1 : 0,
            rows_are_original => !(grep {refaddr($selected->{$_}) != refaddr($all->{$_})} keys %$selected) ? 1 : 0,
            events => records($owner, $selected)};
    };
    {
        no warnings 'redefine';
        no strict 'refs';
        local *{"${build_class}::build_prepared_consolidated_intermediate_block"} = sub {
            my $block = $build->(@_);
            $observe->('prepared', $block);
            $escaped = $block if $options{retain_block};
            $filtered = $block->{filtered_signals} if $options{retain_filtered};
            return $block;
        };
        local *{"${render_class}::render_prepared_consolidated_intermediate_block"} = sub {
            my ($self, $block) = @_;
            $observe->('render_entry', $block);
            die "prepared graph controlled render failure\n" if $options{fail_render};
            my $result = $render->(@_);
            $observe->('render_return', $block);
            return $result;
        };
        eval {$hdl = $ctx->generate_systemverilog($module); 1} or $error = $@;
    }
    return {ctx => $ctx, observations => \@observations, escaped => $escaped,
        filtered => $filtered, hdl => $hdl, error => $error, source => $source};
}
subtest 'ordinary prepared/render ownership preserves current proof without extending lifetime' => sub {
    for my $expression ('(+ A B C)', '(+ A (* B (+ C D)))', '(+ (+ A B C) (+ B C D))') {
        for my $width (1, 8) {
            my $p = fixture($expression, $width);
            is($p->{error}, undef, 'actual ordinary generation succeeds');
            is_deeply([map {$_->{phase}} @{$p->{observations}}], [qw(prepared render_entry render_return)],
                'real prepare and render boundaries were observed');
            my $expected = $p->{observations}[0]{events};
            ok(keys %$expected, 'actual prepared graph proof is current');
            for my $o (@{$p->{observations}}) {
                ok($o->{view_is_weak} && $o->{view_is_original}, 'weak locator follows the actual original map');
                ok($o->{filtered_is_distinct} && $o->{rows_are_original}, 'filtering preserves exact original row objects');
                is_deeply($o->{events}, $expected, 'prepared ownership preserves current proof through render');
            }
            is($p->{ctx}{backend_sv_intermediate_width_support}->_current_graph_inference_rows, undef,
                'ordinary generation releases the weak referent');
            ok(eval {$json->encode($p->{observations}); 1}, 'observations contain only plain detached data');
            my $input = $p->{source};
            my $plain_module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$input));
            my $plain_hdl = FSM::HDL::FlattenedDT->new->generate_systemverilog($plain_module);
            $_ =~ s{^// Date:.*$}{// Date: <time>}mg for ($plain_hdl, $p->{hdl});
            is($p->{hdl}, $plain_hdl, 'non-retaining observations preserve uninstrumented HDL');
        }
    }
};
subtest 'explicit block ownership and filtered-only ownership have distinct lifetimes' => sub {
    my $p = fixture('(+ A (* B (+ C D)))', 8, retain_block => 1);
    my $owner = $p->{ctx}{backend_sv_intermediate_width_support};
    my $expected = $p->{observations}[0]{events};
    ok($owner->_current_graph_inference_rows, 'explicitly retained actual block owns the original map');
    is_deeply(records($owner, $p->{escaped}{filtered_signals}), $expected, 'retained block preserves current actual graph records');
    delete $p->{escaped};
    is($owner->_current_graph_inference_rows, undef, 'dropping the last block owner releases the weak map');
    my $q = fixture('(+ A (* B (+ C D)))', 8, retain_filtered => 1);
    my $other = $q->{ctx}{backend_sv_intermediate_width_support};
    ok(keys %{$q->{filtered}}, 'actual filtered rows remain explicitly owned');
    is($other->_current_graph_inference_rows, undef, 'filtered row values do not retain the containing original map');
    is_deeply(records($other, $q->{filtered}), {}, 'retained row objects alone cannot invent the expired canonical view');
};
subtest 'render failure clears proof and fresh backend reuse restores ordinary lifecycle' => sub {
    my $p = fixture('(+ A (* B C))', 8, fail_render => 1);
    like($p->{error}, qr/prepared graph controlled render failure/, 'original render failure propagates');
    my $owner = $p->{ctx}{backend_sv_intermediate_width_support};
    is($owner->_current_graph_inference_rows, undef, 'failed generation clears weak association');
    is_deeply($owner->{_graph_inference_events}, {}, 'failed generation clears all graph holders');
    my $retry = fixture('(+ A (* B C))', 8, ctx => $p->{ctx});
    is($retry->{error}, undef, 'actual backend can generate afresh');
    ok(keys %{$retry->{observations}[0]{events}}, 'new preparation captures current graph proof');
    is($owner->_current_graph_inference_rows, undef, 'successful reuse still releases its actual row view');
};
done_testing();
