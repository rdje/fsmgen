use v5.20;
use strict;
use warnings;

use Test::More;
use Digest::SHA qw(sha256_hex);
use FindBin qw($Bin);
use Storable qw(dclone);

use lib "$Bin/../perl";

use FSM::Adapter::IAL2::PPIF;
use FSM::IR::SourceHIR;
use FSM::IR::SourceHIRBuilder;
use FSM::IR::SourceHIRPPIFRenderer;

my $repo_root = "$Bin/..";
my $fixture_path = "$repo_root/ppif/valid_ready_handshake.ppif";

sub golden_input {
    return {
        schema_version => 1,
        root_kind => 'protocol_platform_intent',
        intent_name => 'valid_ready_handshake',
        profile => 'valid-ready',
        source_object => {
            id => 'fsmgen-valid-ready-profile',
            anchors => [
                {
                    document => 'FSMGEN-IAL2-VALID-READY-PROFILE',
                    section => 'monitor',
                    page => 'contract',
                },
            ],
        },
        valid_ready_channel => {
            name => 'data_link',
            channel => 'data_link',
            role => 'producer-to-consumer',
            clock => 'clk',
            reset => {
                signal => 'rst_n',
                active_level => 0,
                kind => 'async',
            },
            valid => 'valid',
            ready => 'ready',
            payload => [
                {name => 'data', width => 8},
            ],
        },
        provenance => {
            source_name => 'source-hir/valid_ready_handshake.hir',
            spans => {
                '/' => {
                    start_line => 1,
                    start_column => 1,
                    end_line => 14,
                    end_column => 29,
                },
                '/valid_ready_channel/reset' => {
                    start_line => 7,
                    start_column => 5,
                    end_line => 7,
                    end_column => 36,
                },
                '/valid_ready_channel/payload/0/width' => {
                    start_line => 12,
                    start_column => 20,
                    end_line => 12,
                    end_column => 20,
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
    return FSM::IR::SourceHIRBuilder->validate_valid_ready($input);
}

sub first_diagnostic_after {
    my ($mutator) = @_;
    return diagnostics_after($mutator)->[0];
}

subtest 'package method boundaries are exact and private' => sub {
    can_ok('FSM::IR::SourceHIRBuilder', qw(validate_valid_ready build_valid_ready));
    can_ok('FSM::IR::SourceHIRPPIFRenderer', qw(render_ppif diagnostic_from_ppif_error));
    ok(!FSM::IR::SourceHIR->can('new'), 'SourceHIR has no supported new constructor');

    my $ok = eval { FSM::IR::SourceHIRBuilder::validate_valid_ready(golden_input()); 1 };
    ok(!$ok, 'function-style builder call is rejected');
    like($@, qr/class invocant/, 'function-style builder diagnostic names the class boundary');

    $ok = eval { FSM::IR::SourceHIRBuilder->validate_valid_ready(); 1 };
    ok(!$ok, 'missing builder input is rejected');
    like($@, qr/expects exactly one input hash reference/, 'builder arity diagnostic is stable');

    $ok = eval { FSM::IR::SourceHIRPPIFRenderer->render_ppif({}); 1 };
    ok(!$ok, 'renderer rejects a raw hash in place of SourceHIR');
    like($@, qr/expects one FSM::IR::SourceHIR object/, 'renderer object diagnostic is stable');

    done_testing();
};

subtest 'golden construction is immutable and defensively cloned' => sub {
    my $input = golden_input();
    is_deeply(
        FSM::IR::SourceHIRBuilder->validate_valid_ready($input),
        [],
        'golden input validates without diagnostics',
    );

    my $hir = FSM::IR::SourceHIRBuilder->build_valid_ready($input);
    isa_ok($hir, 'FSM::IR::SourceHIR');
    is($hir->schema_version, 1, 'schema version is normalized');
    is($hir->root_kind, 'protocol_platform_intent', 'root kind is preserved');
    is($hir->intent_name, 'valid_ready_handshake', 'intent name is preserved');
    is($hir->profile, 'valid-ready', 'profile is preserved');

    $input->{source_object}{id} = 'mutated_input';
    is($hir->source_object->{id}, 'fsmgen-valid-ready-profile', 'construction clones caller input');

    my $source = $hir->source_object;
    $source->{anchors}[0]{document} = 'mutated_accessor';
    is(
        $hir->source_object->{anchors}[0]{document},
        'FSMGEN-IAL2-VALID-READY-PROFILE',
        'source-object accessor returns a defensive clone',
    );

    my $channel = $hir->valid_ready_channel;
    $channel->{payload}[0]{width} = 99;
    is($hir->valid_ready_channel->{payload}[0]{width}, 8, 'channel accessor returns a defensive clone');

    my $as_hash = $hir->as_hashref;
    $as_hash->{provenance}{source_name} = 'mutated';
    is(
        $hir->provenance->{source_name},
        'source-hir/valid_ready_handshake.hir',
        'as_hashref does not expose live object storage',
    );

    is_deeply(
        $hir->source_location_for('/valid_ready_channel/payload/0/width'),
        {
            source_name => 'source-hir/valid_ready_handshake.hir',
            start_line => 12,
            start_column => 20,
            end_line => 12,
            end_column => 20,
        },
        'exact semantic path resolves its exact span',
    );
    is_deeply(
        $hir->source_location_for('/valid_ready_channel/payload/0/name'),
        {
            source_name => 'source-hir/valid_ready_handshake.hir',
            start_line => 1,
            start_column => 1,
            end_line => 14,
            end_column => 29,
        },
        'missing leaf span falls back through ancestors to root',
    );

    done_testing();
};

subtest 'closed schema and semantic invariants reject deterministically' => sub {
    my $diagnostics = diagnostics_after(sub {
        $_[0]{zzz} = 1;
        $_[0]{aaa} = 1;
    });
    is_deeply(
        [map { $_->{message} } @$diagnostics[0, 1]],
        ["unsupported field 'aaa'", "unsupported field 'zzz'"],
        'unknown top-level fields are reported lexically first',
    );
    is_deeply(
        [sort keys %{$diagnostics->[0]}],
        [qw(code message phase schema_version semantic_path severity source_location)],
        'validation diagnostic has the exact closed key set',
    );
    is($diagnostics->[0]{code}, 'FSMGEN_SOURCE_HIR_INVALID', 'validation code is stable');
    is($diagnostics->[0]{phase}, 'source_hir_validation', 'validation phase is stable');

    is(first_diagnostic_after(sub { delete $_[0]{schema_version} })->{semantic_path}, '/schema_version', 'missing schema version is rejected');
    is(first_diagnostic_after(sub { $_[0]{root_kind} = 'intent' })->{semantic_path}, '/root_kind', 'wrong root kind is rejected');
    is(first_diagnostic_after(sub { $_[0]{profile} = 'axi4' })->{semantic_path}, '/profile', 'wrong profile is rejected');
    is(first_diagnostic_after(sub { $_[0]{source_object}{id} = 'bad atom' })->{semantic_path}, '/source_object/id', 'non-atom source id is rejected');
    is(first_diagnostic_after(sub { $_[0]{source_object}{anchors} = [] })->{semantic_path}, '/source_object/anchors', 'empty anchors are rejected');
    is(first_diagnostic_after(sub { $_[0]{valid_ready_channel}{channel} = 'bad-name' })->{semantic_path}, '/valid_ready_channel/channel', 'invalid channel identifier is rejected');
    is(first_diagnostic_after(sub { $_[0]{valid_ready_channel}{role} = 'manager' })->{semantic_path}, '/valid_ready_channel/role', 'invalid role is rejected');
    is(first_diagnostic_after(sub { $_[0]{valid_ready_channel}{reset}{active_level} = 2 })->{semantic_path}, '/valid_ready_channel/reset/active_level', 'invalid reset level is rejected');
    is(first_diagnostic_after(sub { $_[0]{valid_ready_channel}{reset}{kind} = 'both' })->{semantic_path}, '/valid_ready_channel/reset/kind', 'invalid reset kind is rejected');
    is(first_diagnostic_after(sub { $_[0]{valid_ready_channel}{payload} = [] })->{semantic_path}, '/valid_ready_channel/payload', 'empty payload is rejected');
    is(first_diagnostic_after(sub { $_[0]{valid_ready_channel}{payload}[0]{width} = 0 })->{semantic_path}, '/valid_ready_channel/payload/0/width', 'non-positive payload width is rejected');
    is(first_diagnostic_after(sub { $_[0]{valid_ready_channel}{ready} = 'valid' })->{semantic_path}, '/valid_ready_channel/ready', 'duplicate interface name is rejected');
    is(
        first_diagnostic_after(sub {
            $_[0]{valid_ready_channel}{valid} = 'data_link_valid_ready_monitor_done';
        })->{semantic_path},
        '/valid_ready_channel/name',
        'derived done collision is attached to channel name',
    );

    my $width_diagnostic = first_diagnostic_after(sub {
        $_[0]{valid_ready_channel}{payload}[0]{width} = 0;
    });
    is($width_diagnostic->{source_location}{start_line}, 12, 'invalid width uses its exact source span');

    done_testing();
};

subtest 'provenance names, paths, and coordinates fail closed' => sub {
    my $diagnostic = first_diagnostic_after(sub {
        $_[0]{provenance}{source_name} = '/machine/local/input.hir';
    });
    is($diagnostic->{semantic_path}, '/provenance/source_name', 'absolute source name is rejected');
    is($diagnostic->{source_location}{source_name}, 'source-hir-input', 'invalid source name is not echoed as provenance');

    like(
        first_diagnostic_after(sub { $_[0]{provenance}{source_name} = '../input.hir' })->{message},
        qr/repository-relative or stable logical name/,
        'parent traversal source name is rejected',
    );
    like(
        first_diagnostic_after(sub { $_[0]{provenance}{source_name} = 'source\\input.hir' })->{message},
        qr/repository-relative or stable logical name/,
        'backslash source name is rejected',
    );
    like(
        first_diagnostic_after(sub { $_[0]{provenance}{spans}{'/not-present'} = dclone($_[0]{provenance}{spans}{'/'}); })->{message},
        qr/not present in SourceHIR v1/,
        'unknown semantic span path is rejected',
    );
    like(
        first_diagnostic_after(sub { $_[0]{provenance}{spans}{'/'}{end_line} = 0; })->{message},
        qr/must be a positive integer/,
        'non-positive span coordinate is rejected',
    );
    like(
        first_diagnostic_after(sub {
            $_[0]{provenance}{spans}{'/'} = {
                start_line => 2, start_column => 4,
                end_line => 2, end_column => 3,
            };
        })->{message},
        qr/end must not precede its start/,
        'reversed same-line span is rejected',
    );

    my $input = golden_input();
    $input->{aaa} = 1;
    my $ok = eval { FSM::IR::SourceHIRBuilder->build_valid_ready($input); 1 };
    ok(!$ok, 'build throws when validation fails');
    like(
        $@,
        qr/\AError \[FSMGEN_SOURCE_HIR_INVALID\] source-hir\/valid_ready_handshake\.hir:1:1 \/: unsupported field 'aaa'\n/,
        'build formats the first structured diagnostic deterministically',
    );

    done_testing();
};

subtest 'canonical renderer is deterministic and byte-identical' => sub {
    my $input = golden_input();
    my $hir = FSM::IR::SourceHIRBuilder->build_valid_ready($input);
    my $rendered = FSM::IR::SourceHIRPPIFRenderer->render_ppif($hir);
    my $fixture = slurp_bytes($fixture_path);

    is_deeply(
        [sort keys %$rendered],
        [qw(format schema_version source_label source_map text)],
        'renderer result has the exact closed key set',
    );
    is($rendered->{schema_version}, 1, 'renderer schema version is one');
    is($rendered->{format}, 'ppif', 'renderer format is PPIF');
    is($rendered->{source_label}, 'source-hir-generated/valid_ready_handshake.ppif', 'generated source label is stable and relative');
    is($rendered->{text}, $fixture, 'rendered text equals the tracked fixture byte-for-byte');
    is(scalar(split /\n/, $rendered->{text}), 14, 'rendered text has fourteen logical lines');
    is(length($rendered->{text}), 428, 'rendered text has 428 bytes');
    is(
        sha256_hex($rendered->{text}),
        '6cbc68152c9e1658a341994bc2ccdd83bdb94b26aedd20d4180c996b5124f7ac',
        'rendered text has the selected SHA-256',
    );
    like($rendered->{text}, qr/[^\n]\n\z/, 'rendered text ends in exactly one newline');
    is(scalar(@{$rendered->{source_map}}), 15, 'source map has fourteen line entries plus root');
    ok((grep { $_->{semantic_path} eq '/' } @{$rendered->{source_map}}), 'source map contains root fallback');
    is_deeply(
        [sort keys %{$rendered->{source_map}[0]}],
        [qw(generated_span semantic_path source_location)],
        'source-map entry has exact closed shape',
    );

    my $fresh = golden_input();
    my $reordered = {
        map { $_ => $fresh->{$_} }
        reverse qw(schema_version root_kind intent_name profile source_object valid_ready_channel provenance)
    };
    my $reordered_hir = FSM::IR::SourceHIRBuilder->build_valid_ready($reordered);
    is_deeply($reordered_hir->as_hashref, $hir->as_hashref, 'hash insertion order does not affect normalized object');
    is(
        FSM::IR::SourceHIRPPIFRenderer->render_ppif($reordered_hir)->{text},
        $rendered->{text},
        'hash insertion order does not affect rendered bytes',
    );

    $rendered->{source_map}[0]{source_location}{source_name} = 'mutated';
    my $rerendered = FSM::IR::SourceHIRPPIFRenderer->render_ppif($hir);
    isnt($rerendered->{source_map}[0]{source_location}{source_name}, 'mutated', 'renderer results share no mutable state');

    done_testing();
};

subtest 'canonical text reparses through the existing IAL2 pipeline' => sub {
    my $hir = FSM::IR::SourceHIRBuilder->build_valid_ready(golden_input());
    my $rendered = FSM::IR::SourceHIRPPIFRenderer->render_ppif($hir);
    my $fixture = slurp_bytes($fixture_path);
    my $adapter = FSM::Adapter::IAL2::PPIF->new();

    my $generated = $adapter->parse_source($rendered->{text}, $rendered->{source_label});
    my $baseline = $adapter->parse_source($fixture, 'ppif/valid_ready_handshake.ppif');

    is($generated->{layer}, 'IAL2', 'generated text remains an IAL2 source');
    is($generated->{kind}, 'protocol_intent.valid_ready_channel', 'generated text selects the valid-ready generator');
    is($generated->{generated_ial1}{text}, $baseline->{generated_ial1}{text}, 'generated IAL1 text equals fixture baseline');
    is_deeply($generated->{generated_ial0}{files}, $baseline->{generated_ial0}{files}, 'generated IAL0 files equal fixture baseline');
    is_deeply($generated->{generated_ial1_schedule_report}, $baseline->{generated_ial1_schedule_report}, 'schedule report equals fixture baseline');
    is_deeply($generated->{report}, $baseline->{report}, 'protocol report equals fixture baseline');
    is($generated->{report}{layering}{direct_ial2_to_ial0}, 0, 'normal IAL2 to IAL1 to IAL0 layering remains explicit');

    my $renderer_source = slurp_bytes("$repo_root/perl/FSM/IR/SourceHIRPPIFRenderer.pm");
    unlike(
        $renderer_source,
        qr/FSM::IAL2::ProtocolIntent::ValidReadyChannel/,
        'renderer has no direct generator dependency',
    );

    done_testing();
};

subtest 'bounded enum and ordered-list variants remain canonical' => sub {
    my $input = golden_input();
    push @{$input->{source_object}{anchors}}, {
        document => 'SECOND-SOURCE',
        section => 'channel',
        page => 'two',
    };
    $input->{valid_ready_channel}{role} = 'consumer-to-producer';
    $input->{valid_ready_channel}{reset}{active_level} = 1;
    $input->{valid_ready_channel}{reset}{kind} = 'sync';
    push @{$input->{valid_ready_channel}{payload}}, {name => 'tag', width => 1};

    is_deeply(
        FSM::IR::SourceHIRBuilder->validate_valid_ready($input),
        [],
        'second role, active-high sync reset, and ordered lists validate',
    );
    my $hir = FSM::IR::SourceHIRBuilder->build_valid_ready($input);
    my $rendered = FSM::IR::SourceHIRPPIFRenderer->render_ppif($hir);
    like(
        $rendered->{text},
        qr/\(anchor \(document FSMGEN-IAL2-VALID-READY-PROFILE\).*\n\s+\(anchor \(document SECOND-SOURCE\).*\)\)\n/s,
        'multiple anchors preserve input order and close the source once',
    );
    like($rendered->{text}, qr/\(reset \(rst_n active_high sync\)\)/, 'reset enum renders canonically');
    like(
        $rendered->{text},
        qr/\(data width 8\)\n\s+\(tag width 1\)\)\)\)\n\z/,
        'multiple payloads preserve order, explicit width one, and root closure',
    );

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(
        $rendered->{text},
        $rendered->{source_label},
    );
    is($result->{report}{target_channel}{role}, 'consumer-to-producer', 'existing adapter preserves alternate role');
    is($result->{report}{bindings}{reset}{active_low}, 0, 'existing adapter preserves active-high reset');
    is($result->{report}{bindings}{reset}{async}, 0, 'existing adapter preserves synchronous reset');
    is_deeply(
        [map { $_->{name} } @{$result->{report}{bindings}{payload}}],
        [qw(data tag)],
        'existing adapter preserves payload order',
    );

    done_testing();
};

subtest 'PPIF diagnostics remap by generated line or root fallback' => sub {
    my $hir = FSM::IR::SourceHIRBuilder->build_valid_ready(golden_input());
    my $rendered = FSM::IR::SourceHIRPPIFRenderer->render_ppif($hir);
    my $label = $rendered->{source_label};

    my $line_diagnostic = FSM::IR::SourceHIRPPIFRenderer->diagnostic_from_ppif_error(
        $rendered,
        "Error: $label:10:8 invalid reset\n at machine/path.pm line 3\n",
    );
    is_deeply(
        [sort keys %$line_diagnostic],
        [qw(code downstream_message generated_location message phase schema_version semantic_path severity source_location)],
        'handoff diagnostic has exact closed shape',
    );
    is($line_diagnostic->{code}, 'FSMGEN_SOURCE_HIR_PPIF_REJECTED', 'handoff code is stable');
    is($line_diagnostic->{semantic_path}, '/valid_ready_channel/reset', 'generated line maps to reset semantic path');
    is($line_diagnostic->{source_location}{start_line}, 7, 'generated line maps to original reset span');
    is_deeply(
        $line_diagnostic->{generated_location},
        {source_label => $label, line => 10, column => 8},
        'generated position is retained structurally',
    );
    unlike($line_diagnostic->{downstream_message}, qr/machine\/path/, 'stack-path line is discarded');

    my $inline_stack = FSM::IR::SourceHIRPPIFRenderer->diagnostic_from_ppif_error(
        $rendered,
        'inline failure at /machine/local/Module.pm line 77',
    );
    is($inline_stack->{downstream_message}, 'inline failure', 'same-line Perl stack suffix is sanitized');
    is($inline_stack->{semantic_path}, '/', 'sanitized stack line does not invent a generated position');

    my $bad_text = $rendered->{text};
    $bad_text =~ s/\(profile valid-ready\)/(profile unsupported-profile)/;
    my $ok = eval {
        FSM::Adapter::IAL2::PPIF->new()->parse_source($bad_text, $label);
        1;
    };
    ok(!$ok, 'current PPIF adapter rejects an unsupported generated profile');
    my $fallback = FSM::IR::SourceHIRPPIFRenderer->diagnostic_from_ppif_error($rendered, $@);
    is($fallback->{semantic_path}, '/', 'current no-line PPIF error falls back to SourceHIR root');
    is($fallback->{source_location}{start_line}, 1, 'root fallback retains original root span');
    is_deeply($fallback->{generated_location}, {source_label => $label}, 'no generated position is invented');
    like(
        $fallback->{downstream_message},
        qr/profile must be valid-ready, axi, axi3, axi4, or axi5/,
        'first downstream error line is retained',
    );
    unlike($fallback->{downstream_message}, qr/ at \S+ line \d+/, 'Perl stack locus is not persisted');

    done_testing();
};

subtest 'private implementation does not advertise a public surface' => sub {
    for my $relative (
        'bin/fsmgen',
        'perl/FSM/Support/CapabilityManifestContract.pm',
        'perl/FSM/Support/NormalizedSemanticReport.pm',
        'perl/FSM/Support/SupportAccountingContract.pm',
    ) {
        my $text = slurp_bytes("$repo_root/$relative");
        unlike($text, qr/SourceHIR/, "$relative does not advertise SourceHIR");
    }

    done_testing();
};

done_testing();
