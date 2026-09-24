#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use JSON::PP ();
use Test::More;
use lib "$FindBin::Bin/../perl";
use FSM::VIAL::Parser;
use FSM::VIAL::SourceProjection;
use FSM::VIAL::SourceInspection;

my $json = JSON::PP->new->canonical;
my $source = read_file('vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial');
my $package = 'ahb_subordinate_base_output_arbitration';
my $fixture = "$package\::fixture::base_output_arbitration";
my $domain = "$fixture\::domain::bus";
my $family_id = "$package\::package::$package\::intent_family::lifecycle_control";
my $flow = "$family_id\::lifecycle::fixture_flow";
my $background = "$flow\::service::background";
my @kinds = qw(dependency dependency service readiness stimulus_start completion drain shutdown finalize deadline deadline failure);
my @names = qw(configured_gate reset_gate background ready stimulus complete drained stopped finalized total startup lifecycle_failure);
sub parse { FSM::VIAL::Parser->parse_source({text => $_[0], source_name => 'inspect.vial', source_catalog => $_[1] // {}}) }
sub inspect { FSM::VIAL::SourceInspection->build(parse(@_)) }
sub condition { +{kind => $_[0], reference_id => $_[1], domain_id => $_[2], operands => $_[3] // []} }
sub all { condition('all', undef, undef, [@_]) }
sub point { condition('lifecycle_point', "$flow\::$_[0]::$_[1]") }
sub dependency { condition('dependency_satisfied', "$flow\::dependency::$_[0]") }
sub service { condition("service_$_[0]", "$background\::milestone::$_[0]") }
sub node { my ($family, $kind) = @_; return (grep { $_->{node_kind} eq $kind } @{$family->{nodes}})[0] }
sub without_locations {
    my ($v) = @_;
    return $v unless ref($v);
    return [map { without_locations($_) } @$v] if ref($v) eq 'ARRAY';
    return $v if JSON::PP::is_bool($v);
    return {map { $_ => without_locations($v->{$_}) } grep { $_ ne 'source_location' } keys %$v};
}
sub source_location {
    my ($text, $prefix) = @_;
    my $start = index($text, $prefix); die "missing $prefix" if $start < 0;
    my ($end, $depth) = ($start, 0);
    do { my $c = substr($text, $end++, 1); $depth++ if $c eq '('; $depth-- if $c eq ')' } while $depth;
    my $before = substr($text, 0, $start); my $through = substr($text, 0, $end);
    return {source_name => 'inspect.vial', start_byte => $start, end_byte_exclusive => $end,
        start_line => 1 + ($before =~ tr/\n/\n/), start_column => $start - rindex($before, "\n"),
        end_line => 1 + ($through =~ tr/\n/\n/), end_column => $end - 1 - rindex($through, "\n")};
}

subtest 'complete lifecycle detail retains authored meaning and explicit defaults' => sub {
    my $ir = parse($source); my $before = $json->encode($ir->as_hashref);
    my $r = FSM::VIAL::SourceInspection->build($ir);
    my $f = $r->{packages}[0]{intent_families}[0];
    is_deeply([sort keys %$f], [sort qw(semantic_id family_id revision semantic_path source_location nodes)], 'closed public family');
    is($f->{semantic_id}, $family_id, 'family identity is exact');
    is($f->{family_id}, 'lifecycle_control', 'registered family retained');
    like($json->encode($f), qr/"revision":1[,}]/, 'revision is a JSON integer');
    is_deeply([map { $_->{node_kind} } @{$f->{nodes}}], \@kinds, 'expanded semantic order retained, including service before readiness');
    for my $i (0 .. $#kinds) {
        my $n = $f->{nodes}[$i];
        is($n->{semantic_id}, "$flow\::$kinds[$i]::$names[$i]", 'independently authored node identity');
        is_deeply($n->{source_location}, source_location($source, "($kinds[$i] $names[$i]"), 'exact authored node coordinates');
        is($n->{order}{rank}, $i, 'semantic rank retained');
        is($n->{payload}{lifecycle_id}, $flow, 'shared lifecycle identity retained');
        is($n->{schema}, 'fsmgen.vial_intent_node.v1', 'independent public node schema');
        ok(!exists($n->{stage}), 'private compiler stage omitted');
    }
    my $ready_id = "$flow\::readiness::ready";
    my @prerequisites = ("$flow\::dependency::configured_gate", "$flow\::dependency::reset_gate", "$background\::milestone::ready");
    my $result_type = 'type/vial_lifecycle_record_result_v1';
    is_deeply(node($f, 'readiness'), {
        schema => 'fsmgen.vial_intent_node.v1', schema_version => 1, semantic_id => $ready_id,
        family_id => 'lifecycle_control', revision => 1, node_id => $ready_id, node_kind => 'readiness',
        scope => {kind => 'fixture', owner_id => $fixture},
        lifetime => {start => 'lifecycle_entered', end => 'result_sealed', cancellation => 'required'},
        order => {domain_id => $domain, phase => 'check', rank => 3, before => [], after => \@prerequisites},
        ports => [map { +{port_id => "$ready_id\::port::$_->[0]", name => $_->[0], direction => $_->[1],
            type_id => $_->[2], cardinality => 'one', required => $_->[3]} }
            ['fixture','input','type/vial_fixture_ref_v1',JSON::PP::true],
            ['domain','input','type/vial_domain_ref_v1',JSON::PP::true],
            ['result','output',$result_type,JSON::PP::false]],
        effects => [{effect_id => "$ready_id\::effect::ready", kind => 'ready', target_id => $fixture, visibility => 'result'}],
        failure => {policy => 'fail_scope', diagnostic_code => 'VIAL_LIFECYCLE_DEADLINE_EXPIRED', scope => 'fixture'},
        result => {kind => 'lifecycle_record', type_id => $result_type, required => JSON::PP::true},
        semantic_path => '/packages/0/intent_families/0/lifecycles/0/readiness',
        source_location => source_location($source, '(readiness ready'),
        payload => {schema => 'fsmgen.vial_lifecycle_control.v1', schema_version => 1,
            lifecycle_id => $flow, fixture_id => $fixture, domain_id => $domain,
            record_kind => 'readiness', record_id => $ready_id,
            condition => all(dependency('configured_gate'), dependency('reset_gate'), service('ready')),
            intrinsic_after => \@prerequisites, additional_after => [], detail => {}},
    }, 'complete public readiness record matches independent semantic oracle');
    is_deeply(node($f,'service')->{payload}{detail}, {
        target => 'fixture_background', cancellation => 'cooperative',
        start_condition => all(condition('configured'), dependency('configured_gate'), dependency('reset_gate')),
        ready_condition => all(service('started')),
        quiescent_condition => all(point('completion','complete'), condition('transactions_terminal'), condition('scoreboards_empty')),
        stop_condition => all(point('shutdown','stopped')),
    }, 'all service conditions and cancellation preserved');
    is_deeply(node($f,'drain')->{payload}{condition}, all(point('completion','complete'),
        condition('transactions_terminal'), condition('scoreboards_empty'), service('quiescent')), 'drain retains intrinsic prerequisites');
    is_deeply(node($f,'finalize')->{payload}{condition}, all(point('shutdown','stopped'),service('stopped')), 'finalization waits for service stop');
    is_deeply(node($f,'deadline')->{payload}{detail}, {
        from => condition('lifecycle_entered', "$flow\::milestone::entered"), until => point('finalize','finalized'),
        max_cycles => 1024, last_cycle_inclusive => JSON::PP::true}, 'full deadline uses inclusive authored domain-cycle bound');
    is_deeply(node($f,'failure')->{payload}{detail}, {disposition => 'fail', cleanup => 'finalize', cleanup_max_cycles => 256, diagnostics => 'all'}, 'failure defaults explicit');
    is_deeply($f->{nodes}[1]{payload}{condition}, condition('reset_inactive', undef, $domain), 'reset references domain, not a record');
    unlike($json->encode($r), qr/"(?:source_span|provenance|plan_id|operation_ids)":/, 'no compiler or execution-only records leak');
    is($json->encode($ir->as_hashref), $before, 'input remains unchanged');
    is_deeply(FSM::VIAL::SourceInspection->build($ir), $r, 'fresh projection deterministic');
    $f->{nodes}[0]{payload}{condition}{kind} = 'mutated';
    is(node(FSM::VIAL::SourceInspection->build($ir)->{packages}[0]{intent_families}[0], 'dependency')->{payload}{condition}{kind}, 'configured', 'caller mutations cannot change later results');
};

subtest 'explicit policies, additional requirements, styles and imports remain inspectable' => sub {
    my $text = $source;
    $text =~ s/\(target fixture_background\)/(target fixture_background)
        (ready_requires (configured))
        (quiescent_requires (dependency_satisfied configured_gate))
        (stop_requires (all (transactions_terminal) (lifecycle_point complete))) (cancellation cooperative)/;
    $text =~ s/\(readiness ready\)/(readiness ready (requires (all (configured) (reset_inactive bus))))/;
    $text =~ s/\(finalize finalized\)/(finalize finalized (requires (dependency_satisfied reset_gate)))/;
    $text =~ s/\(failure lifecycle_failure\)/(failure lifecycle_failure (disposition fail) (cleanup finalize) (cleanup_within 31) (diagnostics first))/;
    $text =~ s/\(within 32\)/(within 17)/;
    my $r = inspect($text); my $f = $r->{packages}[0]{intent_families}[0];
    is_deeply(node($f,'readiness')->{payload}{condition}, all(dependency('configured_gate'),dependency('reset_gate'),service('ready'),
        all(condition('configured'),condition('reset_inactive',undef,$domain))), 'authored nested AND adds to intrinsic prerequisites');
    is_deeply(node($f,'service')->{payload}{detail}{start_condition}, all(condition('configured'),dependency('configured_gate'),dependency('reset_gate')), 'intrinsic start prerequisites retained');
    is_deeply(node($f,'service')->{payload}{detail}{ready_condition}, all(service('started'),condition('configured')), 'authored ready condition retained');
    is_deeply(node($f,'service')->{payload}{additional_after}, ["$flow\::completion::complete"], 'additional service-stage edge retained without duplicating intrinsic dependencies');
    is_deeply(node($f,'finalize')->{payload}{additional_after}, ["$flow\::dependency::reset_gate"], 'explicit finalization dependency retained');
    is(node($f,'failure')->{payload}{detail}{cleanup_max_cycles}, 31, 'explicit cleanup bound retained');
    is(node($f,'failure')->{payload}{detail}{diagnostics}, 'first', 'explicit diagnostic policy retained');
    is($f->{nodes}[10]{payload}{detail}{max_cycles}, 17, 'authored startup bound retained');
    is_deeply(node($f,'service')->{payload}{detail}{quiescent_condition}, all(point('completion','complete'),
        condition('transactions_terminal'),condition('scoreboards_empty'),dependency('configured_gate')), 'authored quiescent condition retained');
    is_deeply(node($f,'service')->{payload}{detail}{stop_condition}, all(point('shutdown','stopped'),
        all(condition('transactions_terminal'),point('completion','complete'))), 'authored stop conjunction retained');
    my $terse = FSM::VIAL::SourceProjection->format_source({text=>$text,source_name=>'inspect.vial',output_style=>'terse'})->{text};
    is_deeply(without_locations(inspect($terse)->{packages}), without_locations($r->{packages}), 'all meaning fields survive normal/terse formatting');
    my $root = read_file('vial/ahb_subordinate_base_output_arbitration_v2.vial');
    $root =~ s/\(imports\)/(imports (import lib "library.vial"))/;
    my $library = $text; $library =~ s/package \Q$package\E/package library/;
    my $import = inspect($root, {'library.vial'=>$library});
    is_deeply($import->{packages}[0]{intent_families}, [], 'root has no invented family');
    my $lf = $import->{packages}[1]{intent_families}[0];
    is($lf->{source_location}{source_name}, 'library.vial', 'imported family retains catalog identity');
    like($lf->{nodes}[0]{payload}{fixture_id}, qr/^library::fixture::/, 'imported family scope stays in its package');
    is($lf->{nodes}[10]{payload}{detail}{max_cycles}, 17, 'imported deadline detail preserved');
};

subtest 'optional service and dependency collections preserve their explicit scope' => sub {
    my $without_service = $source;
    $without_service =~ s/\(services\s+\(service background\s+\(target fixture_background\)\)\)/(services)/ or die 'service fixture missing';
    my $f = inspect($without_service)->{packages}[0]{intent_families}[0];
    ok(!grep({ $_->{node_kind} eq 'service' } @{$f->{nodes}}), 'no service invented when none authored');
    is_deeply(node($f,'readiness')->{payload}{condition}, all(dependency('configured_gate'),dependency('reset_gate')), 'readiness has only actual dependencies');
    is_deeply(node($f,'finalize')->{payload}{condition}, all(point('shutdown','stopped')), 'no invented service-stop prerequisite');
    my $without_dependencies = $source;
    $without_dependencies =~ s/\(dependencies\s+\(dependency configured_gate \(when \(configured\)\)\)\s+\(dependency reset_gate \(when \(reset_inactive bus\)\)\)\)/(dependencies)/ or die 'dependency fixture missing';
    $f = inspect($without_dependencies)->{packages}[0]{intent_families}[0];
    is_deeply(node($f,'readiness')->{payload}{condition}, all(service('ready')), 'service-only readiness remains explicit');
    is_deeply(node($f,'service')->{payload}{detail}{start_condition}, all(condition('configured')), 'service start remains configured with no declared dependencies');
};

subtest 'missing, untyped and inconsistent family records fail closed' => sub {
    my $ir = parse($source); my $raw = $ir->as_hashref;
    my @cases = (
        ['unknown family', sub { $_[0]{family_id}='new_family'; $_->{family_id}='new_family' for @{$_[0]{nodes}} }],
        ['unknown revision', sub { $_[0]{revision}=2; $_->{revision}=2 for @{$_[0]{nodes}} }],
        ['empty family', sub { $_[0]{nodes}=[] }],
        ['missing condition', sub { delete $_[0]{nodes}[0]{payload}{condition} }],
        ['unknown payload field', sub { $_[0]{nodes}[0]{payload}{backend_callback}='host' }],
        ['unknown detail', sub { $_[0]{nodes}[0]{payload}{detail}{extra}=1 }],
        ['unknown kind', sub { $_[0]{nodes}[0]{node_kind}='unknown' }],
        ['object reference', sub { $_[0]{nodes}[3]{payload}{condition}{operands}[0]{reference_id}={} }],
        ['unknown condition', sub { $_[0]{nodes}[0]{payload}{condition}{kind}='unknown' }],
        ['empty all', sub { $_[0]{nodes}[3]{payload}{condition}{operands}=[] }],
        ['excessive all', sub { $_[0]{nodes}[3]{payload}{condition}{operands}=[map { condition('configured') } 1..65] }],
        ['excessive nesting', sub { my $c=condition('configured'); $c=all($c) for 1..16; $_[0]{nodes}[0]{payload}{condition}=$c }],
        ['missing service condition', sub { delete $_[0]{nodes}[2]{payload}{detail}{stop_condition} }],
        ['excessive deadline', sub { $_[0]{nodes}[9]{payload}{detail}{max_cycles}=2147483648 }],
        ['zero deadline', sub { $_[0]{nodes}[9]{payload}{detail}{max_cycles}=0 }],
        ['exclusive deadline', sub { $_[0]{nodes}[9]{payload}{detail}{last_cycle_inclusive}=JSON::PP::false }],
        ['invalid milestone', sub { $_[0]{nodes}[9]{payload}{detail}{from}=condition('configured') }],
        ['negative cleanup', sub { $_[0]{nodes}[11]{payload}{detail}{cleanup_max_cycles}=-1 }],
        ['unknown service target', sub { $_[0]{nodes}[2]{payload}{detail}{target}='uvm' }],
        ['mismatched record', sub { $_[0]{nodes}[0]{payload}{record_id}='other' }],
        ['mismatched fixture', sub { $_[0]{nodes}[0]{payload}{fixture_id}='other' }],
        ['mismatched domain', sub { $_[0]{nodes}[0]{payload}{domain_id}='other' }],
        ['non-null failure condition', sub { $_[0]{nodes}[11]{payload}{condition}=condition('configured') }],
    );
    for my $case (@cases) {
        my $changed = $json->decode($json->encode($raw)); $case->[1]->($changed->{packages}[0]{intent_families}[0]);
        my ($ok,$error);
        { no warnings qw(redefine once); local *FSM::VIAL::SemanticIR::as_hashref=sub{$changed};
          $ok=eval { FSM::VIAL::SourceInspection->build($ir); 1 }; $error=$@; }
        ok(!$ok, "$case->[0] rejected"); ok(length($error // ''), 'projection failure is explicit');
    }
};
ok(!exists $INC{'FSM/VIAL/PlanBuilder.pm'}, 'inspection loads no planner');
ok(!exists $INC{'FSM/VIAL/Backend/Runner.pm'}, 'inspection loads no backend runner');
done_testing();
sub read_file { open my $fh,'<:raw',"$FindBin::Bin/../$_[0]" or die $!; local $/; my $s=<$fh>; close $fh or die $!; return $s }
