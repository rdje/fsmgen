use strict;
use warnings;
use lib 'perl';
use Test::More;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::Backend::VerilogFamily::DeclarationCapture;

sub fixture {
    my ($width) = @_;
    my $source = "(?fsm:phase_order (+params (W $width)) "
        . '(+size (A (param W)) (B (param W)) (DATA 1) (OTHER 1)) '
        . '(idle (<(& A B) (= (DATA 1)) (= (OTHER 1))) (-> idle)))';
    return FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$source));
}

my $stage = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStageSupport';
my $preparation = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStagePreparationSupport';
my $rendering = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateRenderingSupport';
my $widths = 'FSM::DirectDeclaredWidthSupport';
my $prepare = $preparation->can('prepare_consolidated_intermediate_block');
my $render = $rendering->can('render_prepared_consolidated_intermediate_block');
my $source_plan = $widths->can('prepare_module');

subtest 'actual source planning follows collection and precedes the single rendering' => sub {
    for my $width (1, 8) {
        my $module = fixture($width);
        my $ctx = FSM::HDL::FlattenedDT->new;
        my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
        my @events;
        my ($prepared, $rendered);
        my $hdl;
        {
            no warnings 'redefine';
            no strict 'refs';
            local *{"${preparation}::prepare_consolidated_intermediate_block"} = sub {
                $prepared++;
                my $block = $prepare->(@_);
                push @events, 'prepared';
                return $block;
            };
            local *{"${widths}::prepare_module"} = sub {
                push @events, 'source';
                return $source_plan->(@_);
            };
            local *{"${rendering}::render_prepared_consolidated_intermediate_block"} = sub {
                $rendered++;
                push @events, 'render';
                ok($_[0]{flattened_dt}{direct_declared_width_source_plan},
                    'render sees the prepared source plan');
                return $render->(@_);
            };
            local $ctx->{declared_width_declaration_capture} = $capture;
            $hdl = $ctx->generate_systemverilog($module);
        }
        is_deeply([@events[0..2]], ['prepared', 'source', 'render'],
            'source proof occurs after actual discovery and before any rendering');
        is($prepared, 1, 'one actual preparation');
        is($rendered, 1, 'one actual rendering');
        like($hdl, qr/input\s+wire\s+\[\(W - 1\):0\]\s+A\b/,
            'symbolic source port keeps its existing range');
        ok(keys %{$capture->snapshot->{target_intermediates}},
            'actual intermediate events complete normally');
    }
};

subtest 'failed source proof stops before rendering and a reused backend recovers' => sub {
    my $ctx = FSM::HDL::FlattenedDT->new;
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $module = fixture(8);
    my $rendered = 0;
    my $error;
    {
        no warnings 'redefine';
        no strict 'refs';
        local *{"${widths}::prepare_module"} = sub {die "source proof failed\n"};
        local *{"${rendering}::render_prepared_consolidated_intermediate_block"} = sub {
            $rendered++;
            return $render->(@_);
        };
        local $ctx->{declared_width_declaration_capture} = $capture;
        eval {$ctx->generate_systemverilog($module)};
        $error = $@;
    }
    like($error, qr/source proof failed/, 'source refusal propagates');
    is($rendered, 0, 'no declaration or assignment rendering precedes source refusal');
    ok(!eval {$capture->snapshot; 1}, 'failed generation exposes no complete snapshot');
    {
        local $ctx->{declared_width_declaration_capture} = $capture;
        ok($ctx->generate_systemverilog(fixture(1)), 'same backend and collector recover');
    }
    ok($capture->snapshot, 'reused collector exposes only the completed generation');
};

subtest 'split stage preparation validates without rendering' => sub {
    my @events;
    my $ctx = {
        backend_sv_generation_prescan_preparation_support => bless({events => \@events}, 'Local::PhasePrescan'),
        backend_sv_consolidated_intermediate_stage_preparation_support => bless({events => \@events}, 'Local::PhasePreparation'),
        backend_sv_operand_contract_validation_support => bless({events => \@events}, 'Local::PhaseValidator'),
        backend_sv_consolidated_intermediate_rendering_support => bless({events => \@events}, 'Local::PhaseRenderer'),
    };
    my $owner = $stage->new(flattened_dt => $ctx);
    ok($owner->can('prepare_consolidated_intermediate_block'), 'stage exposes prepare/validate boundary');
    return unless $owner->can('prepare_consolidated_intermediate_block');
    my $block = $owner->prepare_consolidated_intermediate_block('module');
    is_deeply(\@events, ['prescan', 'prepare', 'validate'], 'preparation cannot render');
    is($owner->render_prepared_consolidated_intermediate_block($block), 'rendered',
        'render consumes the same prepared object');
    is_deeply(\@events, ['prescan', 'prepare', 'validate', 'render'], 'render is explicit');
    @events = ();
    is($owner->generate_consolidated_intermediate_block('module'), 'rendered', 'combined facade preserves result');
    is_deeply(\@events, ['prescan', 'prepare', 'validate', 'render'], 'combined facade composes one pass');
};

{package Local::PhasePrescan; sub prepare_enable_prescan {push @{$_[0]{events}}, 'prescan'}}
{package Local::PhasePreparation; sub prepare_consolidated_intermediate_block {push @{$_[0]{events}}, 'prepare'; return {module => $_[1]}}}
{package Local::PhaseValidator; sub validate_pre_generation_operand_contract {push @{$_[0]{events}}, 'validate'; die 'wrong block' unless $_[2]{module} eq $_[1]}}
{package Local::PhaseRenderer; sub render_prepared_consolidated_intermediate_block {push @{$_[0]{events}}, 'render'; die 'wrong block' unless $_[1]{module} eq 'module'; return 'rendered'}}

done_testing();
