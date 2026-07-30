#!/usr/bin/env perl
use v5.20;
use strict;
use warnings;

use Test::More;
use Digest::SHA qw(sha256_hex);
use FindBin qw($Bin);
use JSON::PP qw(decode_json);
use Storable qw(dclone);

use lib "$Bin/../perl";

use FSM::Adapter::ISF;
use FSM::IR::SourceHIR;
use FSM::IR::SourceHIRBuilder;
use FSM::IR::SourceHIRISFRenderer;
use FSM::IR::SourceHIRPPIFRenderer;
use FSM::Scheduler::ISF;

my $repo_root = "$Bin/..";
my $fixture_path = "$repo_root/isf/phase_test.isf";

sub golden_input {
    return {
        schema_version => 2,
        root_kind => 'concrete_control',
        actor => {
            name => 'phase_test',
            clock => 'clk',
            reset => {
                signal => 'rst_n',
                active_level => 0,
                kind => 'async',
            },
            ports => [
                {direction => 'input', name => 'start', width => 1},
                {direction => 'output', name => 'done', width => 1},
                {direction => 'output', name => 'rdata', width => 32},
            ],
            drive_blocks => [
                {
                    name => 'rdata',
                    parameters => ['val'],
                    assignments => [
                        {target => 'rdata', value => 'val'},
                    ],
                },
            ],
            transactions => [
                {
                    name => 't',
                    trigger => {signal => 'start'},
                    phases => [
                        {
                            name => 'first_phase',
                            outputs => ['rdata'],
                            next => 'second_phase',
                        },
                        {
                            name => 'second_phase',
                            outputs => ['done'],
                            next => 'last_phase',
                        },
                        {
                            name => 'last_phase',
                            outputs => ['done'],
                        },
                    ],
                    completion => {signal => 'done'},
                },
            ],
        },
        provenance => {
            source_name => 'source-hir/phase_test.hir',
            spans => {
                '/' => {
                    start_line => 1,
                    start_column => 1,
                    end_line => 17,
                    end_column => 22,
                },
                '/actor/reset' => {
                    start_line => 3,
                    start_column => 3,
                    end_line => 3,
                    end_column => 36,
                },
                '/actor/ports/2/width' => {
                    start_line => 8,
                    start_column => 26,
                    end_line => 8,
                    end_column => 27,
                },
                '/actor/transactions/0/phases/1' => {
                    start_line => 15,
                    start_column => 5,
                    end_line => 15,
                    end_column => 61,
                },
            },
        },
    };
}

sub slurp_bytes {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Cannot read '$path': $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Cannot close '$path': $!";
    return $text;
}

sub diagnostics_after {
    my ($mutator) = @_;
    my $input = golden_input();
    $mutator->($input);
    return FSM::IR::SourceHIRBuilder->validate_concrete_control($input);
}

sub first_diagnostic_after {
    my ($mutator) = @_;
    return diagnostics_after($mutator)->[0];
}

subtest 'package method boundaries and root dispatch are exact' => sub {
    can_ok(
        'FSM::IR::SourceHIRBuilder',
        qw(
          validate_valid_ready build_valid_ready
          validate_concrete_control build_concrete_control
        ),
    );
    can_ok(
        'FSM::IR::SourceHIRISFRenderer',
        qw(render_isf diagnostic_from_isf_error),
    );
    ok(!FSM::IR::SourceHIR->can('new'), 'SourceHIR still has no public constructor');

    my $ok = eval { FSM::IR::SourceHIRBuilder::validate_concrete_control(golden_input()); 1 };
    ok(!$ok, 'function-style version-2 builder call is rejected');
    like($@, qr/class invocant/, 'builder diagnostic names the exact class boundary');

    $ok = eval { FSM::IR::SourceHIRBuilder->validate_concrete_control(); 1 };
    ok(!$ok, 'missing version-2 builder input is rejected');
    like($@, qr/expects exactly one input hash reference/, 'builder arity diagnostic is stable');

    $ok = eval { FSM::IR::SourceHIRISFRenderer->render_isf({}); 1 };
    ok(!$ok, 'ISF renderer rejects a raw hash');
    like($@, qr/expects one FSM::IR::SourceHIR object/, 'ISF renderer object diagnostic is stable');

    my $hir = FSM::IR::SourceHIRBuilder->build_concrete_control(golden_input());
    $ok = eval { $hir->intent_name; 1 };
    ok(!$ok, 'version-1 intent accessor rejects the concrete-control root');
    like($@, qr/unavailable for root_kind 'concrete_control'/, 'root-dispatch diagnostic is explicit');

    $ok = eval { FSM::IR::SourceHIRPPIFRenderer->render_ppif($hir); 1 };
    ok(!$ok, 'version-1 PPIF renderer rejects the concrete-control root');
    like($@, qr/unavailable for root_kind 'concrete_control'/, 'PPIF rejection uses root dispatch');

    done_testing();
};

subtest 'golden concrete-control construction is immutable and defensively cloned' => sub {
    my $input = golden_input();
    is_deeply(
        FSM::IR::SourceHIRBuilder->validate_concrete_control($input),
        [],
        'golden version-2 input validates without diagnostics',
    );

    my $hir = FSM::IR::SourceHIRBuilder->build_concrete_control($input);
    isa_ok($hir, 'FSM::IR::SourceHIR');
    is($hir->schema_version, 2, 'schema version is normalized to two');
    is($hir->root_kind, 'concrete_control', 'concrete-control root kind is preserved');
    is($hir->control_actor->{name}, 'phase_test', 'control actor is accessible');

    $input->{actor}{name} = 'mutated_input';
    is($hir->control_actor->{name}, 'phase_test', 'construction clones caller input');

    my $actor = $hir->control_actor;
    $actor->{ports}[2]{width} = 99;
    is($hir->control_actor->{ports}[2]{width}, 32, 'control-actor accessor is defensive');

    my $as_hash = $hir->as_hashref;
    $as_hash->{actor}{transactions}[0]{phases}[0]{name} = 'mutated';
    is(
        $hir->control_actor->{transactions}[0]{phases}[0]{name},
        'first_phase',
        'as_hashref exposes no live object storage',
    );

    is_deeply(
        $hir->source_location_for('/actor/ports/2/width'),
        {
            source_name => 'source-hir/phase_test.hir',
            start_line => 8,
            start_column => 26,
            end_line => 8,
            end_column => 27,
        },
        'exact version-2 semantic path resolves exact provenance',
    );
    is(
        $hir->source_location_for('/actor/ports/1/name')->{start_line},
        1,
        'missing leaf provenance falls back to the root span',
    );

    done_testing();
};

subtest 'closed schema and concrete-control cross references fail deterministically' => sub {
    my $not_hash = FSM::IR::SourceHIRBuilder->validate_concrete_control('not-a-hash')->[0];
    is($not_hash->{schema_version}, 2, 'non-hash validation still uses diagnostic schema two');
    is($not_hash->{semantic_path}, '/', 'non-hash validation attaches to root');

    is(first_diagnostic_after(sub { $_[0]{aaa} = 1 })->{message}, "unsupported field 'aaa'", 'unknown top-level field is rejected first');
    is(first_diagnostic_after(sub { $_[0]{schema_version} = 1 })->{semantic_path}, '/schema_version', 'wrong schema version is rejected');
    is(first_diagnostic_after(sub { $_[0]{root_kind} = 'protocol_platform_intent' })->{semantic_path}, '/root_kind', 'wrong root kind is rejected');
    is(first_diagnostic_after(sub { $_[0]{actor}{ports} = [] })->{semantic_path}, '/actor/ports', 'empty ports are rejected');
    like(first_diagnostic_after(sub { $_[0]{actor}{ports}[1]{name} = 'start' })->{message}, qr/duplicated/, 'duplicate port name is rejected');
    is(first_diagnostic_after(sub { $_[0]{actor}{drive_blocks} = [] })->{semantic_path}, '/actor/drive_blocks', 'exactly one drive is required');
    is(
        first_diagnostic_after(sub { $_[0]{actor}{drive_blocks}[0]{parameters} = 'not-an-array' })->{semantic_path},
        '/actor/drive_blocks/0/parameters',
        'malformed drive parameters fail through structured validation',
    );
    like(first_diagnostic_after(sub { $_[0]{actor}{drive_blocks}[0]{assignments}[0]{target} = 'start' })->{message}, qr/declared output/, 'drive target must be an output');
    like(first_diagnostic_after(sub { $_[0]{actor}{drive_blocks}[0]{assignments}[0]{value} = 'raw_expr' })->{message}, qr/declared parameter/, 'drive value cannot be a raw expression');
    like(first_diagnostic_after(sub { $_[0]{actor}{transactions}[0]{trigger}{signal} = 'rdata' })->{message}, qr/width-1 input/, 'trigger must be a scalar input');
    like(first_diagnostic_after(sub { $_[0]{actor}{transactions}[0]{completion}{signal} = 'rdata' })->{message}, qr/width-1 output/, 'completion must be a scalar output');
    like(first_diagnostic_after(sub { $_[0]{actor}{transactions}[0]{phases}[0]{outputs}[0] = 'start' })->{message}, qr/declared output/, 'phase outputs must be declared outputs');
    like(first_diagnostic_after(sub { $_[0]{actor}{transactions}[0]{phases}[0]{next} = 'last_phase' })->{message}, qr/immediately following phase/, 'phase next edge must preserve linear order');
    like(first_diagnostic_after(sub { $_[0]{actor}{transactions}[0]{phases}[2]{next} = 'first_phase' })->{message}, qr/final phase must omit/, 'final phase cannot add a back edge');

    my @cases = (
        ['actor shape', sub { $_[0]{actor} = 'bad' }, '/actor', qr/hash reference/],
        ['actor unknown key', sub { $_[0]{actor}{aaa} = 1 }, '/actor', qr/unsupported field 'aaa'/],
        ['actor name', sub { $_[0]{actor}{name} = 'bad-name' }, '/actor/name', qr/ISF identifier/],
        ['actor clock', sub { $_[0]{actor}{clock} = 'bad-clock' }, '/actor/clock', qr/ISF identifier/],
        ['reset shape', sub { $_[0]{actor}{reset} = 'bad' }, '/actor/reset', qr/hash reference/],
        ['reset unknown key', sub { $_[0]{actor}{reset}{aaa} = 1 }, '/actor/reset', qr/unsupported field 'aaa'/],
        ['reset signal', sub { $_[0]{actor}{reset}{signal} = 'bad-signal' }, '/actor/reset/signal', qr/ISF identifier/],
        ['reset active level', sub { $_[0]{actor}{reset}{active_level} = 2 }, '/actor/reset/active_level', qr/integer from 0 through 1/],
        ['reset kind', sub { $_[0]{actor}{reset}{kind} = 'edge' }, '/actor/reset/kind', qr/one of async, sync/],
        ['port shape', sub { $_[0]{actor}{ports}[0] = 'bad' }, '/actor/ports/0', qr/hash reference/],
        ['port unknown key', sub { $_[0]{actor}{ports}[0]{aaa} = 1 }, '/actor/ports/0', qr/unsupported field 'aaa'/],
        ['port direction', sub { $_[0]{actor}{ports}[0]{direction} = 'inout' }, '/actor/ports/0/direction', qr/one of input, output/],
        ['port name', sub { $_[0]{actor}{ports}[0]{name} = 'bad-name' }, '/actor/ports/0/name', qr/ISF identifier/],
        ['port width', sub { $_[0]{actor}{ports}[0]{width} = 0 }, '/actor/ports/0/width', qr/positive integer/],
        ['missing input', sub { $_->{direction} = 'output' for @{$_[0]{actor}{ports}} }, '/actor/ports', qr/at least one input/],
        ['missing output', sub { $_->{direction} = 'input' for @{$_[0]{actor}{ports}} }, '/actor/ports', qr/at least one output/],
        ['actor clock identity', sub { $_[0]{actor}{clock} = 'phase_test' }, '/actor', qr/must be distinct/],
        ['clock port collision', sub { $_[0]{actor}{clock} = 'start' }, '/actor/ports', qr/must not collide/],
        ['reset port collision', sub { $_[0]{actor}{reset}{signal} = 'start' }, '/actor/ports', qr/must not collide/],
        ['drive count', sub { push @{$_[0]{actor}{drive_blocks}}, dclone($_[0]{actor}{drive_blocks}[0]) }, '/actor/drive_blocks', qr/exactly one/],
        ['drive shape', sub { $_[0]{actor}{drive_blocks}[0] = 'bad' }, '/actor/drive_blocks/0', qr/hash reference/],
        ['drive unknown key', sub { $_[0]{actor}{drive_blocks}[0]{aaa} = 1 }, '/actor/drive_blocks/0', qr/unsupported field 'aaa'/],
        ['drive name', sub { $_[0]{actor}{drive_blocks}[0]{name} = 'bad-name' }, '/actor/drive_blocks/0/name', qr/ISF identifier/],
        ['empty drive parameters', sub { $_[0]{actor}{drive_blocks}[0]{parameters} = [] }, '/actor/drive_blocks/0/parameters', qr/non-empty array/],
        ['drive parameter identifier', sub { $_[0]{actor}{drive_blocks}[0]{parameters}[0] = 'bad-name' }, '/actor/drive_blocks/0/parameters/0', qr/ISF identifier/],
        ['duplicate drive parameter', sub { push @{$_[0]{actor}{drive_blocks}[0]{parameters}}, 'val' }, '/actor/drive_blocks/0/parameters/1', qr/duplicated/],
        ['unused drive parameter', sub { push @{$_[0]{actor}{drive_blocks}[0]{parameters}}, 'spare' }, '/actor/drive_blocks/0/parameters/1', qr/must be used/],
        ['empty assignments', sub { $_[0]{actor}{drive_blocks}[0]{assignments} = [] }, '/actor/drive_blocks/0/assignments', qr/non-empty array/],
        ['assignment shape', sub { $_[0]{actor}{drive_blocks}[0]{assignments}[0] = 'bad' }, '/actor/drive_blocks/0/assignments/0', qr/hash reference/],
        ['assignment unknown key', sub { $_[0]{actor}{drive_blocks}[0]{assignments}[0]{aaa} = 1 }, '/actor/drive_blocks/0/assignments/0', qr/unsupported field 'aaa'/],
        ['assignment target identifier', sub { $_[0]{actor}{drive_blocks}[0]{assignments}[0]{target} = 'bad-name' }, '/actor/drive_blocks/0/assignments/0/target', qr/ISF identifier/],
        ['assignment value identifier', sub { $_[0]{actor}{drive_blocks}[0]{assignments}[0]{value} = 'bad-name' }, '/actor/drive_blocks/0/assignments/0/value', qr/ISF identifier/],
        ['duplicate assignment target', sub { push @{$_[0]{actor}{drive_blocks}[0]{assignments}}, {target => 'rdata', value => 'val'} }, '/actor/drive_blocks/0/assignments/1/target', qr/duplicated/],
        ['transaction count', sub { $_[0]{actor}{transactions} = [] }, '/actor/transactions', qr/exactly one/],
        ['transaction shape', sub { $_[0]{actor}{transactions}[0] = 'bad' }, '/actor/transactions/0', qr/hash reference/],
        ['transaction unknown key', sub { $_[0]{actor}{transactions}[0]{aaa} = 1 }, '/actor/transactions/0', qr/unsupported field 'aaa'/],
        ['transaction name', sub { $_[0]{actor}{transactions}[0]{name} = 'bad-name' }, '/actor/transactions/0/name', qr/ISF identifier/],
        ['trigger shape', sub { $_[0]{actor}{transactions}[0]{trigger} = 'bad' }, '/actor/transactions/0/trigger', qr/hash reference/],
        ['trigger unknown key', sub { $_[0]{actor}{transactions}[0]{trigger}{aaa} = 1 }, '/actor/transactions/0/trigger', qr/unsupported field 'aaa'/],
        ['trigger identifier', sub { $_[0]{actor}{transactions}[0]{trigger}{signal} = 'bad-name' }, '/actor/transactions/0/trigger/signal', qr/ISF identifier/],
        ['completion shape', sub { $_[0]{actor}{transactions}[0]{completion} = 'bad' }, '/actor/transactions/0/completion', qr/hash reference/],
        ['completion unknown key', sub { $_[0]{actor}{transactions}[0]{completion}{aaa} = 1 }, '/actor/transactions/0/completion', qr/unsupported field 'aaa'/],
        ['completion identifier', sub { $_[0]{actor}{transactions}[0]{completion}{signal} = 'bad-name' }, '/actor/transactions/0/completion/signal', qr/ISF identifier/],
        ['empty phases', sub { $_[0]{actor}{transactions}[0]{phases} = [] }, '/actor/transactions/0/phases', qr/non-empty array/],
        ['phase shape', sub { $_[0]{actor}{transactions}[0]{phases}[0] = 'bad' }, '/actor/transactions/0/phases/0', qr/hash reference/],
        ['phase unknown key', sub { $_[0]{actor}{transactions}[0]{phases}[0]{aaa} = 1 }, '/actor/transactions/0/phases/0', qr/unsupported field 'aaa'/],
        ['phase name', sub { $_[0]{actor}{transactions}[0]{phases}[0]{name} = 'bad-name' }, '/actor/transactions/0/phases/0/name', qr/ISF identifier/],
        ['duplicate phase name', sub { $_[0]{actor}{transactions}[0]{phases}[1]{name} = 'first_phase'; $_[0]{actor}{transactions}[0]{phases}[0]{next} = 'first_phase' }, '/actor/transactions/0/phases/1/name', qr/duplicated/],
        ['empty phase outputs', sub { $_[0]{actor}{transactions}[0]{phases}[0]{outputs} = [] }, '/actor/transactions/0/phases/0/outputs', qr/non-empty array/],
        ['phase output identifier', sub { $_[0]{actor}{transactions}[0]{phases}[0]{outputs}[0] = 'bad-name' }, '/actor/transactions/0/phases/0/outputs/0', qr/ISF identifier/],
        ['duplicate phase output', sub { $_[0]{actor}{transactions}[0]{phases}[1]{outputs} = [qw(done done)] }, '/actor/transactions/0/phases/1/outputs/1', qr/duplicated/],
    );

    for my $case (@cases) {
        my ($label, $mutator, $path, $message) = @$case;
        my $diagnostic = first_diagnostic_after($mutator);
        is($diagnostic->{semantic_path}, $path, "$label uses the expected semantic path");
        like($diagnostic->{message}, $message, "$label has a stable rejection class");
    }

    my $ordered = diagnostics_after(sub {
        $_[0]{zzz} = 1;
        $_[0]{aaa} = 1;
    });
    is_deeply(
        [map { $_->{message} } @$ordered[0, 1]],
        ["unsupported field 'aaa'", "unsupported field 'zzz'"],
        'unknown hash keys are diagnosed in lexical order',
    );

    my $input = golden_input();
    $input->{aaa} = 1;
    my $ok = eval { FSM::IR::SourceHIRBuilder->build_concrete_control($input); 1 };
    ok(!$ok, 'build throws the first version-2 diagnostic');
    like(
        $@,
        qr/\AError \[FSMGEN_SOURCE_HIR_INVALID\] source-hir\/phase_test\.hir:1:1 \/: unsupported field 'aaa'\n/,
        'formatted version-2 build failure is stable and source-located',
    );

    done_testing();
};

subtest 'version-2 provenance names, paths, and coordinates fail closed' => sub {
    my $diagnostic = first_diagnostic_after(sub {
        $_[0]{provenance}{source_name} = '/machine/local/input.hir';
    });
    is($diagnostic->{semantic_path}, '/provenance/source_name', 'absolute source name is rejected');
    is($diagnostic->{source_location}{source_name}, 'source-hir-input', 'invalid source name is not echoed');

    like(
        first_diagnostic_after(sub { $_[0]{provenance}{source_name} = '../input.hir' })->{message},
        qr/repository-relative or stable logical name/,
        'parent traversal is rejected',
    );
    like(
        first_diagnostic_after(sub {
            $_[0]{provenance}{spans}{'/valid_ready_channel'} = dclone($_[0]{provenance}{spans}{'/'});
        })->{message},
        qr/not present in SourceHIR version 2/,
        'version-1-only semantic path is rejected by the version-2 registry',
    );
    like(
        first_diagnostic_after(sub { $_[0]{provenance}{spans}{'/'}{end_line} = 0 })->{message},
        qr/must be a positive integer/,
        'non-positive coordinate is rejected',
    );
    like(
        first_diagnostic_after(sub {
            $_[0]{provenance}{spans}{'/'} = {
                start_line => 2, start_column => 4,
                end_line => 2, end_column => 3,
            };
        })->{message},
        qr/end must not precede its start/,
        'reversed span is rejected',
    );

    done_testing();
};

subtest 'canonical ISF rendering is deterministic and byte-identical' => sub {
    my $input = golden_input();
    my $hir = FSM::IR::SourceHIRBuilder->build_concrete_control($input);
    my $rendered = FSM::IR::SourceHIRISFRenderer->render_isf($hir);
    my $fixture = slurp_bytes($fixture_path);

    is_deeply(
        [sort keys %$rendered],
        [qw(format schema_version source_label source_map text)],
        'renderer result has the exact closed key set',
    );
    is($rendered->{schema_version}, 2, 'renderer schema version is two');
    is($rendered->{format}, 'isf', 'renderer format is ISF');
    is($rendered->{source_label}, 'source-hir-generated/phase_test.isf', 'generated source label is stable and relative');
    is($rendered->{text}, $fixture, 'rendered text equals the tracked fixture byte-for-byte');
    is(scalar(split /\n/, $rendered->{text}), 17, 'rendered text has seventeen logical lines');
    is(length($rendered->{text}), 395, 'rendered text has 395 bytes');
    is(
        sha256_hex($rendered->{text}),
        '6eeab6c6f2e87c4a91f97fd8c0f2535334a163a7ccf263f30dfcefae51b0d2f2',
        'rendered text has the selected SHA-256',
    );
    like($rendered->{text}, qr/[^\n]\n\z/, 'rendered text ends in exactly one newline');
    is(scalar(@{$rendered->{source_map}}), 15, 'source map has fourteen non-empty line entries plus root');
    ok((grep { $_->{semantic_path} eq '/' } @{$rendered->{source_map}}), 'source map contains root fallback');

    my $fresh = golden_input();
    my $reordered = {
        map { $_ => $fresh->{$_} }
        reverse qw(schema_version root_kind actor provenance)
    };
    my $reordered_hir = FSM::IR::SourceHIRBuilder->build_concrete_control($reordered);
    is_deeply($reordered_hir->as_hashref, $hir->as_hashref, 'hash insertion order does not affect normalized object');
    is(
        FSM::IR::SourceHIRISFRenderer->render_isf($reordered_hir)->{text},
        $rendered->{text},
        'hash insertion order does not affect rendered bytes',
    );

    $rendered->{source_map}[0]{source_location}{source_name} = 'mutated';
    isnt(
        FSM::IR::SourceHIRISFRenderer->render_isf($hir)->{source_map}[0]{source_location}{source_name},
        'mutated',
        'renderer results share no mutable state',
    );

    done_testing();
};

subtest 'bounded ordered variants remain canonical and parseable' => sub {
    my $input = golden_input();
    $input->{actor}{name} = 'phase_variant';
    $input->{actor}{clock} = 'clock_i';
    $input->{actor}{reset} = {signal => 'reset_i', active_level => 1, kind => 'sync'};
    $input->{actor}{ports} = [
        {direction => 'input', name => 'request', width => 1},
        {direction => 'output', name => 'complete_o', width => 1},
        {direction => 'output', name => 'payload_o', width => 4},
        {direction => 'output', name => 'tag_o', width => 2},
    ];
    $input->{actor}{drive_blocks}[0] = {
        name => 'payload_o',
        parameters => [qw(value tag)],
        assignments => [
            {target => 'payload_o', value => 'value'},
            {target => 'tag_o', value => 'tag'},
        ],
    };
    $input->{actor}{transactions}[0] = {
        name => 'flow',
        trigger => {signal => 'request'},
        phases => [
            {name => 'prepare', outputs => [qw(payload_o tag_o)], next => 'finish'},
            {name => 'finish', outputs => ['complete_o']},
        ],
        completion => {signal => 'complete_o'},
    };
    $input->{provenance} = {
        source_name => 'source-hir/phase_variant.hir',
        spans => {'/' => dclone(golden_input()->{provenance}{spans}{'/'})},
    };

    is_deeply(
        FSM::IR::SourceHIRBuilder->validate_concrete_control($input),
        [],
        'alternate names, ordering, widths, reset, assignments, and phase count validate',
    );
    my $rendered = FSM::IR::SourceHIRISFRenderer->render_isf(
        FSM::IR::SourceHIRBuilder->build_concrete_control($input),
    );
    like($rendered->{text}, qr/\(reset \(reset_i sync active_high\)\)/, 'alternate reset renders canonically');
    like($rendered->{text}, qr/\(output payload_o \(width 4\)\)\n\s+\(output tag_o \(width 2\)\)\)/, 'ordered widths render canonically');
    like($rendered->{text}, qr/\(drive \(payload_o value tag\) \(payload_o value\) \(tag_o tag\)\)/, 'ordered drive data renders canonically');
    like($rendered->{text}, qr/\(phase prepare \(outputs payload_o tag_o\) \(next finish\)\)/, 'ordered phase outputs render canonically');

    my $actor = FSM::Adapter::ISF->new()->parse_source($rendered->{text}, $rendered->{source_label});
    is($actor->{actor_name}, 'phase_variant', 'alternate canonical source reparses');
    is(scalar(@{$actor->{interface}{outputs}}), 3, 'alternate output order reaches typed actor');

    done_testing();
};

subtest 'canonical text reparses and preserves exact IAL0 and schedule' => sub {
    my $rendered = FSM::IR::SourceHIRISFRenderer->render_isf(
        FSM::IR::SourceHIRBuilder->build_concrete_control(golden_input()),
    );
    my $fixture = slurp_bytes($fixture_path);
    my $adapter = FSM::Adapter::ISF->new();
    my $generated_actor = $adapter->parse_source($rendered->{text}, $rendered->{source_label});
    my $baseline_actor = $adapter->parse_source($fixture, 'isf/phase_test.isf');

    is_deeply($generated_actor, $baseline_actor, 'generated and hand-written text produce identical typed actors');

    my $generated_scheduler = FSM::Scheduler::ISF->new();
    my $baseline_scheduler = FSM::Scheduler::ISF->new();
    my $generated = $generated_scheduler->lower($generated_actor);
    my $baseline = $baseline_scheduler->lower($baseline_actor);
    is_deeply([sort keys %{$generated->{files}}], ['phase_test.fsm'], 'generated path produces one exact IAL0 file');
    is_deeply($generated->{files}, $baseline->{files}, 'generated and hand-written paths produce equal IAL0 files');

    my $fsm = $generated->{files}{'phase_test.fsm'};
    is(scalar(split /\n/, $fsm), 45, 'generated IAL0 has forty-five logical lines');
    is(length($fsm), 484, 'generated IAL0 has 484 bytes');
    is(
        sha256_hex($fsm),
        '8b82ddb329a6b625d0ec271d9611b35140414a2c84e775c1615e442cdfa65047',
        'generated IAL0 has the selected SHA-256',
    );

    my $generated_report = decode_json($generated_scheduler->report($generated_actor));
    my $baseline_report = decode_json($baseline_scheduler->report($baseline_actor));
    is_deeply($generated_report, $baseline_report, 'generated and hand-written paths produce equal schedule reports');
    is($generated_report->{state_count}, 5, 'schedule retains five states');
    is($generated_report->{port_count}, 3, 'schedule retains three ports');
    is_deeply(
        $generated_report->{transactions}[0]{states},
        [qw(t_idle_0 t_phase_1 t_phase_2 t_phase_3 t_done_4)],
        'schedule retains exact transaction state order',
    );

    my $renderer_source = slurp_bytes("$repo_root/perl/FSM/IR/SourceHIRISFRenderer.pm");
    unlike($renderer_source, qr/FSM::Adapter::ISF/, 'renderer has no ISF adapter dependency');
    unlike($renderer_source, qr/FSM::Scheduler::ISF/, 'renderer has no scheduler dependency');

    done_testing();
};

subtest 'ISF diagnostics remap by generated line or truthful root fallback' => sub {
    my $rendered = FSM::IR::SourceHIRISFRenderer->render_isf(
        FSM::IR::SourceHIRBuilder->build_concrete_control(golden_input()),
    );
    my $label = $rendered->{source_label};

    my $line_diagnostic = FSM::IR::SourceHIRISFRenderer->diagnostic_from_isf_error(
        $rendered,
        "Error: $label:15:8 invalid phase\n at machine/path.pm line 3\n",
    );
    is_deeply(
        [sort keys %$line_diagnostic],
        [qw(code downstream_message generated_location message phase schema_version semantic_path severity source_location)],
        'handoff diagnostic has the exact closed shape',
    );
    is($line_diagnostic->{schema_version}, 2, 'handoff diagnostic uses schema two');
    is($line_diagnostic->{code}, 'FSMGEN_SOURCE_HIR_ISF_REJECTED', 'handoff code is stable');
    is($line_diagnostic->{semantic_path}, '/actor/transactions/0/phases/1', 'generated line maps to second phase');
    is($line_diagnostic->{source_location}{start_line}, 15, 'mapped phase uses its original source span');

    my $actual_error;
    eval {
        FSM::Adapter::ISF->new()->parse_source('(actor broken', $label);
        1;
    } or $actual_error = $@;
    ok(defined($actual_error) && length($actual_error), 'existing parser supplies an actual no-position error');
    my $fallback = FSM::IR::SourceHIRISFRenderer->diagnostic_from_isf_error($rendered, $actual_error);
    is($fallback->{semantic_path}, '/', 'current no-position parser error falls back to SourceHIR root');
    is($fallback->{source_location}{source_name}, 'source-hir/phase_test.hir', 'root fallback preserves original source name');
    unlike($fallback->{downstream_message}, qr/\.pm line/, 'Perl stack path is stripped from downstream message');
    is_deeply(
        $fallback->{generated_location},
        {source_label => 'source-hir-generated/phase_test.isf'},
        'root fallback invents no generated line or column',
    );

    done_testing();
};

subtest 'private implementation adds no public SourceHIR surface' => sub {
    for my $relative (
        'bin/fsmgen',
        'perl/FSM/Support/LanguageSurfaceSection.pm',
        'perl/FSM/Support/RegressionCorpus.pm',
    ) {
        unlike(slurp_bytes("$repo_root/$relative"), qr/SourceHIR|source_hir/, "$relative does not advertise SourceHIR");
    }

    done_testing();
};

done_testing();
