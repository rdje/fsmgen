use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::Backend::VerilogFamily::DeclarationCapture;
use FSM::DirectDeclaredWidthSupport;

my $class = 'FSM::DirectDeclaredWidthSupport';
my $json = JSON::PP->new->canonical;
unless ($class->can('prepare_target_namespace')) {
    fail('separate canonical target namespace preparation exists');
    done_testing();
    exit;
}
sub copy {return $json->decode($json->encode($_[0]))}
sub fixture {
    my $text = '(?fsm:namespace_probe (+params (W 1)) (+size (DATA (param W)) (SOURCE 1))'
        .' (idle (<-= (DATA SOURCE))))';
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$text));
    my $backend = FSM::HDL::FlattenedDT->new;
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    {
        local $backend->{declared_width_declaration_capture} = $capture;
        $backend->generate_systemverilog($module);
    }
    my $snapshot = $capture->snapshot;
    return {fsm_module => $module, assignment_analysis => $backend->{assignment_analysis},
        target_language => 'systemverilog', map {$_ => $snapshot->{$_}} qw(target_namespace target_declarations)};
}
sub namespace {return $class->prepare_target_namespace(%{$_[0]})}
sub full {return $class->prepare_declarations(%{$_[0]})}
sub caller_state {
    my $in = shift;
    return $json->encode({source => $class->prepare_module(%$in),
        namespace => $in->{target_namespace}, declarations => $in->{target_declarations}});
}

subtest 'actual emitted namespaces detach without granting numeric agreement' => sub {
    my $in = fixture();
    my $before = caller_state($in);
    my $plan = namespace($in);
    is($plan->{kind}, 'direct_target_namespace', 'namespace has an explicit narrower contract');
    is_deeply($plan->{source_plan}, $class->prepare_module(%$in), 'source plan uses canonical actual module preparation');
    is_deeply($plan->{namespace}, $in->{target_namespace}, 'complete physical namespace preserves');
    is_deeply($plan->{declarations}, $in->{target_declarations}, 'complete captured declaration metadata preserves');
    is_deeply($plan->{signal_targets}, {DATA => 'DATA', SOURCE => 'SOURCE', next_DATA => 'next_DATA'},
        'actual source names bind to unique physical declarations');
    is($plan->{roles}{next_DATA}, 'ports', 'port role remains separate from storage');
    is($plan->{roles}{DATA}, 'signals', 'storage role preserves');
    ok(full($in), 'existing complete validator still admits the native captured generation');
    is(caller_state($in), $before, 'complete original source and target kinds conserve');
    $plan->{namespace}{parameter_names}[0] = 'CHANGED';
    $plan->{declarations}{DATA}{width} = 99;
    $plan->{source_plan}{signals}{DATA}{width} = 99;
    is(caller_state($in), $before, 'editing detached output changes no original producer');
};

subtest 'namespace validity never licenses a source width signedness type or state mismatch' => sub {
    my $in = fixture();
    for my $change (
        sub {$_[0]{DATA}{width} = 8},
        sub {$_[0]{DATA}{signed} = 1},
        sub {$_[0]{DATA}{declared_type_name} = 'foreign_type'},
        sub {$_[0]{DATA}{state_model} = 'foreign_state'},
    ) {
        local $in->{target_declarations} = copy($in->{target_declarations});
        $change->($in->{target_declarations});
        my $before = caller_state($in);
        ok(namespace($in), 'structural namespace proof remains independent of numeric/type agreement');
        ok(!eval {full($in); 1}, 'full validator retains its separate mismatch refusal');
        like($@, qr/disagrees/, 'original source agreement diagnostic remains');
        is(caller_state($in), $before, 'refusal and narrower preparation preserve caller records');
    }
};

subtest 'canonical namespace and source membership refusals are shared by both consumers' => sub {
    my $in = fixture();
    for my $change (
        sub {$_[0]{target_namespace}{module_name} = 'foreign_module'},
        sub {pop @{$_[0]{target_namespace}{parameter_names}}},
        sub {push @{$_[0]{target_namespace}{constants}}, 'DATA'},
        sub {$_[0]{target_namespace}{identifier_map}{DATA} = 'SOURCE'},
        sub {delete $_[0]{target_declarations}{DATA}},
        sub {my $in = shift; delete $in->{target_declarations}{DATA};
            @{$in->{target_namespace}{signals}} = grep {$_ ne 'DATA'} @{$in->{target_namespace}{signals}}},
        sub {$_[0]{target_declarations}{EXTRA} = {name => 'EXTRA', width => 1, signed => 0}},
        sub {$_[0]{target_declarations}{DATA}{width} = 0},
        sub {$_[0]{target_declarations}{DATA}{signed} = 2},
        sub {$_[0]{target_namespace}{signals} = {}},
    ) {
        local $in->{target_namespace} = copy($in->{target_namespace});
        local $in->{target_declarations} = copy($in->{target_declarations});
        $change->($in);
        my $before = caller_state($in);
        ok(!eval {namespace($in); 1}, 'narrow namespace validator refuses broken physical closure');
        my $namespace_error = $@;
        ok(!eval {full($in); 1}, 'complete validator refuses the same broken physical closure');
        my ($first_namespace) = split /\n/, $namespace_error;
        my ($first_full) = split /\n/, $@;
        is($first_full, $first_namespace, 'shared validator retains the exact primary diagnostic');
        is(caller_state($in), $before, 'both failed consumers conserve full input records');
    }
};

done_testing();
