#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::LanguageSurfaceSection qw(build_language_surface_section);
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);
use FSM::VIAL::Parser;
use FSM::VIAL::SemanticIR;
use FSM::VIAL::SemanticReport;

my $source_name = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $source_path = File::Spec->catfile($FindBin::Bin, '..', split m{/}, $source_name);
open my $source_fh, '<:raw', $source_path or die "Cannot read $source_name: $!";
local $/;
my $source = <$source_fh>;
close $source_fh or die "Cannot close $source_name: $!";

sub check_source {
    my ($text, $catalog) = @_;
    return FSM::VIAL::Parser->check_source({
        text => $text,
        source_name => $source_name,
        source_catalog => $catalog || {},
    });
}

sub changed {
    my ($text, $from, $to, $label) = @_;
    my $copy = $text;
    my $count = ($copy =~ s/\Q$from\E/$to/);
    die "Test mutation '$label' did not match" unless $count == 1;
    return $copy;
}

sub first_form_text {
    my ($text, $head) = @_;
    my $start = index($text, "($head");
    die "Cannot find form '$head'" if $start < 0;
    my ($depth, $in_string, $escaped) = (0, 0, 0);
    for my $index ($start .. length($text) - 1) {
        my $char = substr($text, $index, 1);
        if ($in_string) {
            if ($escaped) {
                $escaped = 0;
            }
            elsif ($char eq '\\') {
                $escaped = 1;
            }
            elsif ($char eq '"') {
                $in_string = 0;
            }
            next;
        }
        if ($char eq '"') {
            $in_string = 1;
        }
        elsif ($char eq '(') {
            ++$depth;
        }
        elsif ($char eq ')') {
            --$depth;
            return substr($text, $start, $index - $start + 1) if $depth == 0;
        }
    }
    die "Unterminated form '$head'";
}

sub duplicate_first_form {
    my ($text, $head) = @_;
    my $form = first_form_text($text, $head);
    return changed($text, $form, "$form\n$form", "duplicate $head");
}

sub failure_is {
    my ($label, $text, $code, $message_pattern, $path_pattern, $catalog) = @_;
    my $checked = check_source($text, $catalog);
    ok(!$checked->{ok}, "$label fails closed");
    is(scalar(@{$checked->{diagnostics}}), 1, "$label returns one deterministic diagnostic");
    my $diagnostic = $checked->{diagnostics}[0];
    is($diagnostic->{code}, $code, "$label uses $code");
    like($diagnostic->{message}, $message_pattern, "$label explains the rejected boundary");
    like($diagnostic->{semantic_path}, $path_pattern, "$label retains a stable semantic path");
    is_deeply(
        [sort keys %{$diagnostic}],
        [sort qw(schema_version severity code phase message semantic_path source_location notes)],
        "$label diagnostic is a closed hash",
    );
    like($diagnostic->{source_location}{source_name}, qr{\Avial/[A-Za-z0-9_./-]+\.vial\z}, "$label diagnostic keeps repository-relative source identity");
    ok($diagnostic->{source_location}{start_line} >= 1, "$label diagnostic carries a one-based line");
    ok($diagnostic->{source_location}{start_column} >= 1, "$label diagnostic carries a one-based Unicode-scalar column");
    return $diagnostic;
}

sub contains_parser_node {
    my ($value) = @_;
    return 0 unless ref($value);
    if (ref($value) eq 'HASH') {
        return 1 if exists($value->{node_kind}) || exists($value->{atom_kind}) || exists($value->{raw});
        return scalar grep { contains_parser_node($value->{$_}) } keys %{$value};
    }
    if (ref($value) eq 'ARRAY') {
        return scalar grep { contains_parser_node($_) } @{$value};
    }
    return 1;
}

subtest 'checked AHB source constructs immutable typed semantic intent' => sub {
    my $checked = check_source($source);
    ok($checked->{ok}, 'checked source succeeds');
    is_deeply($checked->{diagnostics}, [], 'positive check has no diagnostics');
    my $report = $checked->{semantic_report};
    is($report->{schema_version}, 1, 'report schema version is one');
    is($report->{language}, 'vial', 'report identifies VIAL');
    is($report->{language_version}, 1, 'report identifies language version one');
    is($report->{profile}, 'core_directed_single_clock_v1', 'report derives the selected profile');
    is_deeply(
        $report->{required_capabilities},
        [qw(vial.profile.core_directed_single_clock_v1 vial.semantic_ir.v1 vial.source.v1)],
        'report advertises only the three selected capabilities in sorted order',
    );
    is($report->{root_source}{content_sha256}, sha256_hex($source), 'report source identity uses exact checked bytes');
    is(scalar(@{$report->{packages}}), 1, 'report contains one package');
    is(scalar(@{$report->{packages}[0]{fixtures}}), 1, 'report contains one fixture');
    is(scalar(@{$report->{packages}[0]{fixtures}[0]{scenarios}}), 2, 'report contains both directed scenarios');
    is(scalar(@{$report->{unresolved_bridge_refs}}), 7, 'report keeps all opaque unit/domain/endpoint/transaction bridge references unresolved');

    my $ir = FSM::VIAL::Parser->parse_source({ text => $source, source_name => $source_name });
    isa_ok($ir, 'FSM::VIAL::SemanticIR');
    is($ir->schema_version, 1, 'IR schema version is one');
    is($ir->language_version, 1, 'IR language version is one');
    is($ir->profile, 'core_directed_single_clock_v1', 'IR profile is exact');
    ok(!contains_parser_node($ir->as_hashref), 'durable IR contains no lexer token or parser form nodes');
    ok(!$ir->can('bind') && !$ir->can('plan') && !$ir->can('emit') && !$ir->can('run'), 'semantic object exposes no bridge, plan, output, or runtime method');
};

subtest 'semantic order, IDs, values, provenance, and reports are deterministic' => sub {
    my $first = FSM::VIAL::Parser->parse_source({ text => $source, source_name => $source_name });
    my $second = FSM::VIAL::Parser->parse_source({ source_catalog => {}, source_name => $source_name, text => $source });
    is_deeply($first->as_hashref, $second->as_hashref, 'hash insertion order does not change semantic data');
    my $json = JSON::PP->new->canonical(1);
    is($json->encode(FSM::VIAL::SemanticReport->build($first)), $json->encode(FSM::VIAL::SemanticReport->build($second)), 'sanitized report is byte-deterministic under canonical JSON');

    my $data = $first->as_hashref;
    is_deeply(
        $data->{required_capabilities},
        [qw(vial.profile.core_directed_single_clock_v1 vial.semantic_ir.v1 vial.source.v1)],
        'private IR keeps sorted unique capabilities',
    );
    my $fixture = $data->{packages}[0]{fixtures}[0];
    is($fixture->{semantic_id}, 'ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration', 'fixture stable ID contains names rather than ordinals');
    my $ready = $fixture->{dut}{endpoints}[0];
    is($ready->{semantic_id}, 'ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::endpoint::ready_out', 'endpoint stable ID extends the named fixture ID');
    my $size_value = $fixture->{faults}[0]{substitute}{value};
    is_deeply(
        $size_value,
        { kind => 'logic_vector', width => 3, signed => 0, value_bits => '7', known_mask => '7', z_mask => '0' },
        'four-state values normalize to target-neutral value/known/Z masks',
    );
    my $location = $first->source_location_for('/packages/0/fixtures/0/dut/endpoints/0');
    is($location->{source_name}, $source_name, 'provenance lookup returns repository-relative source name');
    ok($location->{start_byte} < $location->{end_byte_exclusive}, 'provenance uses half-open byte offsets');
    ok($location->{start_line} > 1, 'provenance retains authored line coordinates');
    is_deeply($location, $first->source_location_for('/packages/0/fixtures/0/dut/endpoints/0/unrecorded-child'), 'provenance lookup falls back to the nearest recorded ancestor');
};

subtest 'contextual scalar inference is symmetric without implicit conversion' => sub {
    my $reversed_same = changed($source, '(same (sample response) #b0)', '(same #b0 (sample response))', 'reversed same');
    ok(check_source($reversed_same)->{ok}, 'four-state literal on the left infers its exact type from the sampled endpoint');
    my $reversed_order = changed($source, '(>= (choice success_wait) 1)', '(<= 1 (choice success_wait))', 'reversed comparison');
    ok(check_source($reversed_order)->{ok}, 'integer literal on the left infers its exact type from the random choice');
};

subtest 'caller inputs and every structured result are defensively independent' => sub {
    my $catalog = {};
    my $args = { text => $source, source_name => $source_name, source_catalog => $catalog };
    my $ir = FSM::VIAL::Parser->parse_source($args);
    $args->{text} = '(broken)';
    $args->{source_catalog}{'vial/injected.vial'} = '(broken)';
    is($ir->profile, 'core_directed_single_clock_v1', 'mutating invocation input cannot change existing IR');

    my $packages = $ir->packages;
    $packages->[0]{name} = 'mutated';
    is($ir->packages->[0]{name}, 'ahb_subordinate_base_output_arbitration', 'packages accessor is defensive');
    my $sources = $ir->sources;
    $sources->[0]{content_sha256} = 'mutated';
    is($ir->sources->[0]{content_sha256}, sha256_hex($source), 'sources accessor is defensive');
    my $provenance = $ir->provenance;
    $provenance->{'/packages/0'}{start_line} = 999;
    isnt($ir->provenance->{'/packages/0'}{start_line}, 999, 'provenance accessor is defensive');

    my $report = FSM::VIAL::SemanticReport->build($ir);
    $report->{packages}[0]{fixtures}[0]{name} = 'mutated';
    is(FSM::VIAL::SemanticReport->build($ir)->{packages}[0]{fixtures}[0]{name}, 'base_output_arbitration', 'reports do not share mutable branches');
    my $private_error = eval { FSM::VIAL::SemanticIR->_new_validated({}); 1 };
    ok(!$private_error, 'raw SemanticIR constructor remains private');
    like($@, qr/_new_validated is private/, 'private constructor explains its boundary');
};

subtest 'lexical and list grammar rejects invalid encoding, newlines, strings, literals, tokens, and structure' => sub {
    failure_is('invalid UTF-8', "\xff", 'VIAL_LEX_ERROR', qr/valid UTF-8/, qr{^/$});
    failure_is('bare CR', changed($source, "\n", "\r", 'bare CR'), 'VIAL_LEX_ERROR', qr/bare CR/, qr{^/$});
    failure_is('NUL', "\x00$source", 'VIAL_LEX_ERROR', qr/NUL/, qr{^/$});
    failure_is('invalid string escape', changed($source, 'unit/ahb_lite_subordinate', 'unit\\qahb', 'string escape'), 'VIAL_LEX_ERROR', qr/JSON string escape/, qr{^/$});
    failure_is('invalid four-state literal', changed($source, '#b111', '#b112', 'literal'), 'VIAL_LEX_ERROR', qr/invalid token/, qr{^/$});
    failure_is('invalid reader token', changed($source, '(version 1)', q{'(version 1)}, 'reader token'), 'VIAL_LEX_ERROR', qr/invalid token/, qr{^/$});
    failure_is('unclosed root list', substr($source, 0, length($source) - 2), 'VIAL_PARSE_ERROR', qr/unterminated/, qr{^/$});
    failure_is('source byte limit', $source . (' ' x (1_048_577 - length($source))), 'VIAL_LIMIT_ERROR', qr/1048576-byte limit/, qr{^/$});
    my $deep = ('(' x 129) . '(reset bus 1)' . (')' x 129);
    failure_is('list nesting limit', changed($source, '(reset bus 3)', $deep, 'list nesting'), 'VIAL_LIMIT_ERROR', qr/list nesting exceeds the 128-level limit/, qr{^/$});
};

subtest 'closed root and package sections reject wrong, duplicate, misordered, and unknown forms' => sub {
    failure_is('wrong root', changed($source, '(vial', '(verification', 'root'), 'VIAL_PARSE_ERROR', qr/expected 'vial'/, qr{^/$});
    failure_is('wrong version', changed($source, '(version 1)', '(version 2)', 'version'), 'VIAL_LIMIT_ERROR', qr/bounded range 1 through 1/, qr{/language_version$});
    failure_is('misordered sections', changed($source, "    (imports)\n    (types", "    (types)\n    (imports", 'section order'), 'VIAL_PARSE_ERROR', qr/expected 'imports'/, qr{/packages/0/imports$});
    failure_is('duplicate package section', changed($source, "    (imports)\n", "    (imports)\n    (imports)\n", 'duplicate section'), 'VIAL_PARSE_ERROR', qr/requires 8 items/, qr{/packages/0$});
    failure_is('unknown action extension', changed($source, '(reset bus 3)', '(raw_systemverilog "x")', 'unknown action'), 'VIAL_PARSE_ERROR', qr/unknown action/, qr{/actions/0$});
};

subtest 'imports are catalog-only, repository-relative, unique, qualified, and acyclic' => sub {
    my $imported = changed($source, 'package ahb_subordinate_base_output_arbitration', 'package imported_fixture', 'imported package');
    my $root = changed($source, '(imports)', '(imports (import common "vial/common.vial"))', 'positive import');
    $root = changed($root, '(address (type address_t))', '(address (type common.address_t))', 'qualified imported type');
    my $positive = check_source($root, { 'vial/common.vial' => $imported });
    ok($positive->{ok}, 'caller-supplied in-memory import parses without filesystem lookup');
    is_deeply(
        [map { $_->{source_name} } @{$positive->{semantic_report}{sources}}],
        [$source_name, 'vial/common.vial'],
        'source order is root followed by depth-first authored imports',
    );
    is($positive->{semantic_report}{packages}[0]{imports}[0]{package_id}, 'imported_fixture::package::imported_fixture', 'import resolves to an explicit package ID');
    my $import_ir = FSM::VIAL::Parser->parse_source({
        text => $root,
        source_name => $source_name,
        source_catalog => { 'vial/common.vial' => $imported },
    })->as_hashref;
    is(
        $import_ir->{packages}[0]{transactions}[0]{fields}[0]{type}{semantic_id},
        'imported_fixture::type::address_t',
        'qualified type reference resolves through its explicit import alias',
    );

    failure_is('unsafe import', changed($source, '(imports)', '(imports (import common "../common.vial"))', 'unsafe import'), 'VIAL_IMPORT_ERROR', qr/unsafe VIAL source name/, qr{^/$});
    failure_is('missing import', $root, 'VIAL_IMPORT_ERROR', qr/missing catalog source/, qr{/imports$});
    my $duplicate = changed($source, '(imports)', '(imports (import a "vial/common.vial") (import a "vial/other.vial"))', 'duplicate alias');
    failure_is('duplicate import alias', $duplicate, 'VIAL_IMPORT_ERROR', qr/duplicate import alias/, qr{/imports/1/alias$}, {
        'vial/common.vial' => $imported,
        'vial/other.vial' => changed($imported, 'package imported_fixture', 'package other_fixture', 'other package'),
    });
    my $cycle_root = changed($source, '(imports)', '(imports (import common "vial/common.vial"))', 'cycle root');
    my $cycle_import = changed($imported, '(imports)', "(imports (import root \"$source_name\"))", 'cycle import');
    failure_is('cyclic import', $cycle_root, 'VIAL_IMPORT_ERROR', qr/import cycle/, qr{/imports$}, {
        'vial/common.vial' => $cycle_import,
        $source_name => $cycle_root,
    });
    failure_is(
        'package name conflict',
        $cycle_root,
        'VIAL_REFERENCE_ERROR',
        qr/duplicate package name/,
        qr{/packages/1/name$},
        { 'vial/common.vial' => $source },
    );
};

subtest 'declarations and references reject duplicates, recursion, overflow, and unresolved names' => sub {
    failure_is('duplicate type', changed($source, '(type data_t (logic 32))', "(type data_t (logic 32))\n      (type data_t (logic 32))", 'duplicate type'), 'VIAL_REFERENCE_ERROR', qr/duplicate type declaration/, qr{/types/3/name$});
    failure_is('unresolved type', changed($source, '(type address_t)', '(type absent_t)', 'unresolved type'), 'VIAL_REFERENCE_ERROR', qr/unknown type reference/, qr{/type$});
    failure_is('enum overflow', changed($source, '(enum htrans_t (logic 2)', '(enum htrans_t (logic 1)', 'enum overflow'), 'VIAL_TYPE_ERROR', qr/width does not match/, qr{/members/[01]/value$});
    my $recursive = changed($source, '(type address_t (logic 32))', "(type address_t (type data_t))", 'recursive first');
    $recursive = changed($recursive, '(type data_t (logic 32))', '(type data_t (type address_t))', 'recursive second');
    failure_is('recursive aliases', $recursive, 'VIAL_TYPE_ERROR', qr/recursive type alias/, qr{/types/1$});
    failure_is('width limit', changed($source, '(type address_t (logic 32))', '(type address_t (logic 65537))', 'width'), 'VIAL_LIMIT_ERROR', qr/bounded range 1 through 65536/, qr{/width$});
    failure_is('list limit', changed($source, '(type address_t (logic 32))', '(type address_t (list 65537 bool))', 'list length'), 'VIAL_LIMIT_ERROR', qr/bounded range 1 through 65536/, qr{/length$});
    my $record_fields = join ' ', map { "(f$_ bool)" } 0 .. 256;
    failure_is('record field limit', changed($source, '(type address_t (logic 32))', "(type address_t (record $record_fields))", 'record fields'), 'VIAL_LIMIT_ERROR', qr/record exceeds 256 fields/, qr{/type$});
    failure_is('unknown qualified name', changed($source, '(type address_t)', '(type missing.address_t)', 'unknown import alias'), 'VIAL_REFERENCE_ERROR', qr/unknown import alias/, qr{/type$});
};

subtest 'exact typing rejects signedness, X/Z coercion, incomplete fields, unknown arithmetic, and invalid equality' => sub {
    failure_is('negative into unsigned field', changed($source, '(wait_cycles 1)', '(wait_cycles -1)', 'signedness'), 'VIAL_TYPE_ERROR', qr/does not fit/, qr{/value/value$});
    failure_is('X into two-state field', changed($source, '(wait_cycles 1)', '(wait_cycles #bxxxx)', 'xz coercion'), 'VIAL_TYPE_ERROR', qr/cannot coerce/, qr{/value/value$});
    failure_is('incomplete transaction fields', changed($source, "                  (write true)\n", '', 'incomplete fields'), 'VIAL_REFERENCE_ERROR', qr/field 'write' is missing/, qr{/fields$});
    failure_is('four-state arithmetic', changed($source, '(state (count (u 32) 0))', '(state (count (logic 32) #b00000000000000000000000000000000))', 'unknown arithmetic'), 'VIAL_TYPE_ERROR', qr/arithmetic requires a two-state/, qr{/expression/operands/0$});
    failure_is('shape-mismatched equality', changed($source, '(same (sample response) #b0)', '(same (sample response) true)', 'equality mismatch'), 'VIAL_TYPE_ERROR', qr/Boolean context requires|does not exactly match|numeric scalar context requires/, qr{/operands/1});
};

subtest 'models reject nondeterminism, missing rules, and bad assignment targets' => sub {
    failure_is('duplicate model rule', changed($source, '(rules (on tick (set count (+ count 1))))', '(rules (on tick (set count (+ count 1))) (on tick (set count (+ count 1))))', 'duplicate rule'), 'VIAL_REFERENCE_ERROR', qr/duplicate model rule/, qr{/rules/1});
    failure_is('missing model rule', changed($source, '(rules (on tick (set count (+ count 1))))', '(rules)', 'missing rule'), 'VIAL_PARSE_ERROR', qr/requires at least 2 items/, qr{/rules$});
    failure_is('unknown model state target', changed($source, '(set count (+ count 1))', '(set absent (+ count 1))', 'state target'), 'VIAL_REFERENCE_ERROR', qr/unknown model state/, qr{/state$});
};

subtest 'every named semantic namespace rejects duplicate or unresolved identities' => sub {
    failure_is('duplicate transaction event', changed($source, '(events requested accepted captured held completed error)', '(events requested accepted accepted captured held completed error)', 'event'), 'VIAL_REFERENCE_ERROR', qr/duplicate transaction event/, qr{/events/2});
    failure_is('duplicate model input', changed($source, '(inputs (tick event))', '(inputs (tick event) (tick event))', 'model input'), 'VIAL_REFERENCE_ERROR', qr/duplicate model input/, qr{/inputs/1});
    failure_is('duplicate model state', changed($source, '(state (count (u 32) 0))', '(state (count (u 32) 0) (count (u 32) 0))', 'model state'), 'VIAL_REFERENCE_ERROR', qr/duplicate model state/, qr{/state/1});
    failure_is('duplicate endpoint alias', changed($source, '(endpoint response ', '(endpoint ready_out ', 'endpoint alias'), 'VIAL_REFERENCE_ERROR', qr/duplicate endpoint alias/, qr{/endpoints/1});
    failure_is('duplicate instance', changed($source, '(model completions event_counter', '(model accepts event_counter', 'instance'), 'VIAL_REFERENCE_ERROR', qr/duplicate fixture instance/, qr{/instances/1});
    failure_is('duplicate coverage bin', changed($source, '(bin stalled normal', '(bin not_stalled normal', 'bin'), 'VIAL_REFERENCE_ERROR', qr/duplicate coverage bin/, qr{/bins/1});
    failure_is('duplicate fiber', changed($source, '(fiber stall', '(fiber complete', 'fiber'), 'VIAL_REFERENCE_ERROR', qr/duplicate fiber/, qr{/fibers/1});
    failure_is('duplicate expectation', changed($source, '(expect completed_once', '(expect accepted_once', 'expectation'), 'VIAL_REFERENCE_ERROR', qr/duplicate expectation/, qr{/actions/5});
    failure_is('duplicate scenario', changed($source, '(scenario unsupported_size', '(scenario success', 'scenario'), 'VIAL_REFERENCE_ERROR', qr/duplicate scenario/, qr{/scenarios/1});
    failure_is('duplicate fault', duplicate_first_form($source, 'fault unsupported_size'), 'VIAL_REFERENCE_ERROR', qr/duplicate fault/, qr{/faults/1});
    failure_is('duplicate choice', duplicate_first_form($source, 'choice success_wait'), 'VIAL_REFERENCE_ERROR', qr/duplicate random choice/, qr{/choices/1});
    failure_is('duplicate handle', duplicate_first_form($source, 'start success_write'), 'VIAL_REFERENCE_ERROR', qr/duplicate transaction handle/, qr{/actions/3/handle});
    failure_is('unknown handle event', changed($source, '(event error_write completed)', '(event absent completed)', 'handle'), 'VIAL_REFERENCE_ERROR', qr/unknown transaction or handle/, qr{/owner$});

    my $coverpoint = first_form_text($source, 'coverpoint stall_seen');
    my $coverpoint_two = $coverpoint;
    $coverpoint_two =~ s/coverpoint stall_seen/coverpoint stall_seen_two/;
    my $cross_source = changed(
        $source,
        $coverpoint,
        "$coverpoint\n          $coverpoint_two\n          (cross stall_cross (points stall_seen stall_seen_two) (max_bins 4))\n          (cross stall_cross (points stall_seen stall_seen_two) (max_bins 4))",
        'duplicate cross',
    );
    failure_is('duplicate cross', $cross_source, 'VIAL_REFERENCE_ERROR', qr/duplicate coverage item/, qr{/coverage/3});
};

subtest 'bounded time, storage, concurrency, and profile limits fail before IR construction' => sub {
    failure_is('zero timeout', changed($source, '(timeout (cycles bus 256))', '(timeout (cycles bus 0))', 'timeout'), 'VIAL_LIMIT_ERROR', qr/bounded range 1 through 2147483647/, qr{/timeout/cycles$});
    failure_is('zero scoreboard capacity', changed($source, '(capacity 4)', '(capacity 0)', 'scoreboard'), 'VIAL_LIMIT_ERROR', qr/bounded range 1 through 1000000/, qr{/capacity$});
    failure_is('zero fault duration', changed($source, '(duration (cycles bus 1))', '(duration (cycles bus 0))', 'fault'), 'VIAL_LIMIT_ERROR', qr/bounded range 1 through 2147483647/, qr{/duration/cycles$});
    failure_is('zero property window', changed($source, '(event error_write completed) 1 256', '(event error_write completed) 0 256', 'window'), 'VIAL_LIMIT_ERROR', qr/bounded range 1 through 2147483647/, qr{/min_cycles$});
    my $one_fiber = changed($source, "                (fiber stall\n                  (await (within (same (sample ready_out) #b0) 1 256)))", '', 'parallel shape');
    failure_is('one-fiber parallel', $one_fiber, 'VIAL_PARSE_ERROR', qr/requires at least 4 items/, qr{/parallel|/actions/});
    my $multi_domain = changed($source, '(domains (domain bus "domain/ahb_bus"))', '(domains (domain bus "domain/ahb_bus") (domain aux "domain/aux"))', 'multi domain');
    failure_is('multiple domains', $multi_domain, 'VIAL_PROFILE_UNSUPPORTED', qr/requires exactly one fixture domain/, qr{/domains$});
    failure_is('native hierarchy', changed($source, '(logic 32) verification_probe', '(logic 32) native_hierarchy', 'native hierarchy'), 'VIAL_PROFILE_UNSUPPORTED', qr/native_hierarchy/, qr{/access$});
    failure_is('zero repeat', changed($source, '(reset bus 3)', '(repeat 0 (reset bus 3))', 'repeat'), 'VIAL_LIMIT_ERROR', qr/bounded range 1 through 1000000/, qr{/count$});
    failure_is('expanded action limit', changed($source, '(reset bus 3)', '(repeat 65536 (reset bus 1))', 'expanded actions'), 'VIAL_LIMIT_ERROR', qr/exceeds 65536 expanded actions/, qr{/scenarios/0$});

    my $wide_parallel = '(parallel all ' . join(' ', map { "(fiber f$_ (reset bus 1))" } 0 .. 256) . ')';
    failure_is('parallel fiber limit', changed($source, first_form_text($source, 'parallel all'), $wide_parallel, 'parallel fibers'), 'VIAL_LIMIT_ERROR', qr/exceeds 256 fibers/, qr{/parallel|/actions/});

    my $nested_parallel = '(reset bus 1)';
    for my $depth (1 .. 17) {
        $nested_parallel = "(parallel all (fiber nested$depth $nested_parallel) (fiber sibling$depth (reset bus 1)))";
    }
    failure_is('parallel nesting limit', changed($source, first_form_text($source, 'parallel all'), $nested_parallel, 'parallel nesting'), 'VIAL_LIMIT_ERROR', qr/nesting exceeds 16 levels/, qr{/fibers/0/actions/0$});

    my $coverpoint = first_form_text($source, 'coverpoint stall_seen');
    my $coverpoint_two = $coverpoint;
    $coverpoint_two =~ s/coverpoint stall_seen/coverpoint stall_seen_two/;
    my $zero_cross = changed(
        $source,
        $coverpoint,
        "$coverpoint\n          $coverpoint_two\n          (cross stall_cross (points stall_seen stall_seen_two) (max_bins 0))",
        'zero cross limit',
    );
    failure_is('zero cross max bins', $zero_cross, 'VIAL_LIMIT_ERROR', qr/bounded range 1 through 1000000/, qr{/max_bins$});

    for my $unsupported (
        ['absolute-time action', '(delay_ns 10)'],
        ['host callback', '(host_call callback)'],
        ['recursive action', '(recurse success)'],
        ['dynamic loop', '(while true (reset bus 1))'],
        ['raw HDL block', '(systemverilog "initial begin end")'],
    ) {
        failure_is(
            $unsupported->[0],
            changed($source, '(reset bus 3)', $unsupported->[1], $unsupported->[0]),
            'VIAL_PARSE_ERROR', qr/unknown action/, qr{/actions/0$},
        );
    }
};

subtest 'thrown diagnostics are stable, sanitized, and contain no stack or host path' => sub {
    my $bad = changed($source, '(version 1)', '(version 2)', 'throw form');
    my $ok = eval {
        FSM::VIAL::Parser->parse_source({ text => $bad, source_name => $source_name });
        1;
    };
    ok(!$ok, 'parse_source throws on invalid source');
    like($@, qr{\AError \[VIAL_LIMIT_ERROR\] vial/ahb_subordinate_base_output_arbitration\.vial:2:12 /language_version: integer is outside the bounded range 1 through 1\n\z}, 'throw format is exact and one-line');
    unlike($@, qr{(?:/Volumes/|/Users/| at \S+ line \d+)}, 'throw contains no machine path or Perl stack');

    my $unknown = FSM::VIAL::Parser->check_source({ text => $source, source_name => $source_name, unexpected => 1 });
    ok(!$unknown->{ok}, 'unknown invocation key fails closed');
    is($unknown->{diagnostics}[0]{code}, 'VIAL_SEMANTIC_ERROR', 'invocation error is sanitized');
    my $extra = FSM::VIAL::Parser->check_source({ text => $source, source_name => $source_name }, {});
    ok(!$extra->{ok}, 'extra invocation argument fails closed');
    like($extra->{diagnostics}[0]{message}, qr/exactly one invocation hash/, 'invocation arity boundary is explicit');
};

subtest 'independent semantic errors are collected in authored order without cascades' => sub {
    my $fixture = first_form_text($source, 'fixture ');
    my $first = changed($fixture, 'base_output_arbitration', 'bad_domains', 'first fixture name');
    $first = changed(
        $first,
        '(domains (domain bus "domain/ahb_bus"))',
        '(domains (domain bus "domain/ahb_bus") (domain aux "domain/aux"))',
        'first fixture semantic error',
    );
    my $second = changed($fixture, 'base_output_arbitration', 'bad_duration', 'second fixture name');
    $second = changed(
        $second,
        '(duration (cycles bus 1))',
        '(duration (cycles bus 0))',
        'second fixture semantic error',
    );
    my $checked = check_source(changed($source, $fixture, "$first\n$second", 'two invalid fixtures'));

    ok(!$checked->{ok}, 'independently invalid fixtures fail closed');
    is(scalar(@{$checked->{diagnostics}}), 2, 'one diagnostic is retained for each invalid fixture container');
    is_deeply(
        [map { $_->{code} } @{$checked->{diagnostics}}],
        [qw(VIAL_PROFILE_UNSUPPORTED VIAL_LIMIT_ERROR)],
        'diagnostics follow authored source order rather than validation-phase order',
    );
    like($checked->{diagnostics}[0]{semantic_path}, qr{/fixtures/0/dut/domains$}, 'first diagnostic identifies the first fixture');
    like($checked->{diagnostics}[1]{semantic_path}, qr{/fixtures/1/faults/0/duration/cycles$}, 'second diagnostic identifies the second fixture');
    is($checked->{semantic_report}, undef, 'invalid input never exposes partial semantic IR or a report');
};

subtest 'support and capability accounting state semantic-only claims and every non-claim' => sub {
    my ($entry) = grep { $_->{id} eq 'verification.vial_ahb_subordinate_base_output_arbitration' } regression_corpus_entries();
    ok($entry, 'regression corpus contains the checked VIAL source');
    is($entry->{source_kind}, 'vial', 'support entry identifies VIAL source kind');
    is_deeply($entry->{supported_phases}, [qw(parse typecheck semantic_report)], 'support entry claims only parse/typecheck/semantic-report');
    is_deeply(
        $entry->{required_capabilities},
        [qw(vial.profile.core_directed_single_clock_v1 vial.semantic_ir.v1 vial.source.v1)],
        'support entry advertises only selected capabilities',
    );
    is_deeply(
        $entry->{explicit_nonclaims},
        [qw(bridge_binding execution_plan artifact_generation compile simulation result parity uvm vhdl mixed_language scale)],
        'support entry explicitly denies every deferred output/runtime/qualification claim',
    );
    ok(!$entry->{strict_supported}, 'support entry does not imply the unrelated FSM strict-mode CLI');

    my $surface = build_language_surface_section();
    my ($vial) = grep { $_->{suffix} eq '.vial' } @{$surface->{file_surfaces}{entries}};
    is($vial->{status}, 'shipped_bounded_semantic_only', 'capability manifest limits VIAL status to semantic-only');
    is_deeply($vial->{supported_cli_modes}, [], 'capability manifest advertises no public VIAL CLI');
    is_deeply($vial->{lowers_to}, [], 'capability manifest advertises no VIAL lowering');
    is_deeply($vial->{generated_review_artifacts}, [], 'capability manifest advertises no generated VIAL artifact');
};

done_testing();
