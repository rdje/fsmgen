#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $tempdir = tempdir(CLEANUP => 1);
my $ok_path = File::Spec->catfile($tempdir, 'semantic_json_ok.fsm');
my $ok_out_path = File::Spec->catfile($tempdir, 'semantic_json_ok.sv');
my $bad_path = File::Spec->catfile($tempdir, 'semantic_json_bad_infix.fsm');
my $bad_out_path = File::Spec->catfile($tempdir, 'semantic_json_bad_infix.sv');

write_file(
    $ok_path,
    <<'FSM'
(?fsm:semantic_json_ok
  (+system
    (clock clk)
    (sreset reset)
  )

  (+size
    (COND 1)
    (SRC 8)
    (OUT 8)
  )

  (idle
    (<COND
      (= (OUT SRC))
    )
  )
)
FSM
);

write_file(
    $bad_path,
    <<'FSM'
(?fsm:semantic_json_bad_infix
  (+system
    (clock clk)
    (sreset reset)
  )

  (+size
    (SRC 8)
    (OUT 8)
  )

  (idle
    (OUT = SRC)
  )
)
FSM
);

subtest 'semantic JSON reports strict-clean direct-root semantics without emitting HDL' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', '-o', $ok_out_path, $ok_path],
    );

    ok($success, 'semantic JSON succeeds for a strict-clean source');
    is(join('', @{$stderr_buf || []}), '', 'successful semantic JSON does not print stderr');
    ok(!-e $ok_out_path, 'successful semantic JSON does not emit an HDL file');

    my $decoded = decode_json(join('', @{$stdout_buf || []}));
    is($decoded->{normalized_semantic_schema_version}, 1, 'semantic report exposes schema version');
    ok($decoded->{success}, 'semantic report marks success true');
    is($decoded->{command}{mode}, 'semantic_export', 'semantic report records semantic export mode');
    ok($decoded->{command}{json}, 'semantic report records JSON mode');
    ok($decoded->{command}{strict_mode}, 'semantic report records strict mode');
    is($decoded->{source}{resolved_path}, File::Spec->rel2abs($ok_path), 'semantic report records resolved source path');
    is(scalar(@{$decoded->{diagnostics}}), 0, 'semantic report has no diagnostics');
    ok(!$decoded->{support_accounting}{matched}, 'ad-hoc success records unmatched support accounting');
    ok(!$decoded->{generated_output}{emitted}, 'semantic report says no generated output was emitted');

    my $semantic = $decoded->{semantic};
    is($semantic->{module}{name}, 'semantic_json_ok', 'semantic module summary records module name');
    is($semantic->{module}{source_root_kind}, 'fsm', 'semantic module summary records root kind');
    is($semantic->{module}{state_count}, 1, 'semantic module summary records state count');
    is($semantic->{module}{signal_count}, 2, 'semantic module summary records active signal count');
    is($semantic->{system_contract}{reset_kind}, 'sync', 'semantic JSON preserves reset kind');
    is($semantic->{system_contract}{reset_active_level}, 1, 'semantic JSON preserves reset polarity');

    my ($src_entry) = grep { $_->{name} eq 'SRC' } @{$semantic->{signal_analysis}{inputs} || []};
    ok($src_entry, 'semantic signal analysis exposes input entries');
    ok(!exists $src_entry->{signal}, 'semantic signal analysis does not leak live Signal objects');

    my ($intent_src_entry) = grep { $_->{name} eq 'SRC' }
        @{$semantic->{forward_ir}{intent_hir}{signal_analysis}{inputs} || []};
    ok($intent_src_entry, 'semantic forward IR exposes sanitized intent signal analysis');
    ok(!exists $intent_src_entry->{signal}, 'semantic forward IR omits private Signal objects too');
    ok(!exists $decoded->{hdl_code}, 'semantic report does not expose generated HDL text');
    ok(!exists $decoded->{raw_ast}, 'semantic report does not expose private raw AST');
};

subtest 'semantic JSON alias succeeds without an explicit output path' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--semantic-json', $ok_path],
    );

    ok($success, 'semantic JSON alias succeeds');
    is(join('', @{$stderr_buf || []}), '', 'semantic JSON alias keeps stderr clean');

    my $decoded = decode_json(join('', @{$stdout_buf || []}));
    ok($decoded->{success}, 'semantic JSON alias reports success');
    is($decoded->{semantic}{module}{name}, 'semantic_json_ok', 'semantic JSON alias emits semantic payload');
    ok(!$decoded->{generated_output}{emitted}, 'semantic JSON alias emits no HDL');
};

subtest 'semantic JSON reports stable diagnostics for rejected sources' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', '-o', $bad_out_path, $bad_path],
    );

    ok(!$success, 'semantic JSON exits non-zero for a rejected source');
    is(join('', @{$stderr_buf || []}), '', 'failed semantic JSON does not print stderr');
    ok(!-e $bad_out_path, 'failed semantic JSON does not emit an HDL file');

    my $decoded = decode_json(join('', @{$stdout_buf || []}));
    ok(!$decoded->{success}, 'failure report marks success false');
    is($decoded->{normalized_semantic_schema_version}, 1, 'failure report exposes semantic schema version');
    is($decoded->{command}{mode}, 'semantic_export', 'failure report records semantic export mode');
    ok($decoded->{command}{strict_mode}, 'failure report records strict mode');
    is($decoded->{source}{resolved_path}, File::Spec->rel2abs($bad_path), 'failure report records resolved source path');
    is(scalar(@{$decoded->{diagnostics}}), 1, 'failure report carries one diagnostic');
    is($decoded->{diagnostics}[0]{code}, 'FSMGEN_STRICT_INFIX_ASSIGNMENT', 'failure report emits stable diagnostic code');
    ok($decoded->{support_accounting}{matched}, 'failure report exposes matched support accounting at report level');
    is(
        $decoded->{support_accounting}{entry_id},
        'legacy.infix_assignment.strict_rejection',
        'failure report-level support accounting records matched entry id',
    );
    ok(!$decoded->{generated_output}{emitted}, 'failure report says no generated output was emitted');
    ok(!exists $decoded->{semantic}, 'failed semantic report does not expose partial semantics');
};

subtest 'semantic JSON support accounting works for corpus-backed direct and composition sources' => sub {
    assert_corpus_semantic_json(
        relpath => 'fsm/apb_requester.fsm',
        entry_id => 'protocol.apb_requester',
        module_name => 'apb_requester',
        source_root_kind => 'fsm',
    );

    my $composition = assert_corpus_semantic_json(
        relpath => 'fsm/apb_tb.fsm',
        entry_id => 'protocol.apb_tb',
        module_name => 'apb_tb',
        source_root_kind => 'top',
    );
    is($composition->{semantic}{composition}{child_count}, 2, 'composition semantic JSON records child count');
    is(
        $composition->{semantic}{forward_ir}{structural_rtl_ir}{instance_count},
        2,
        'composition semantic JSON exposes structural instance count',
    );
    ok(
        scalar(@{$composition->{semantic}{composition}{children} || []}) >= 2,
        'composition semantic JSON exposes sanitized child summaries',
    );
};

done_testing();

sub assert_corpus_semantic_json {
    my (%args) = @_;
    my $path = File::Spec->catfile($repo_root, split m{/}, $args{relpath});
    my $out_path = File::Spec->catfile($tempdir, "$args{entry_id}.semantic.sv");
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', '-o', $out_path, $path],
    );

    ok($success, "$args{entry_id} succeeds through semantic JSON");
    is(join('', @{$stderr_buf || []}), '', "$args{entry_id} keeps stderr clean through semantic JSON");
    ok(!-e $out_path, "$args{entry_id} emits no HDL through semantic JSON");

    my $decoded = decode_json(join('', @{$stdout_buf || []}));
    ok($decoded->{success}, "$args{entry_id} reports semantic JSON success");
    ok($decoded->{support_accounting}{matched}, "$args{entry_id} records matched support accounting");
    is($decoded->{support_accounting}{entry_id}, $args{entry_id},
        "$args{entry_id} records matched corpus entry id");
    is($decoded->{semantic}{module}{name}, $args{module_name},
        "$args{entry_id} records semantic module name");
    is($decoded->{semantic}{module}{source_root_kind}, $args{source_root_kind},
        "$args{entry_id} records semantic source root kind");
    is($decoded->{semantic}{forward_ir}{intent_hir}{module_name}, $args{module_name},
        "$args{entry_id} exposes sanitized intent HIR");
    is($decoded->{semantic}{forward_ir}{structural_rtl_ir}{module_name}, $args{module_name},
        "$args{entry_id} exposes sanitized structural RTL IR");
    if ($args{source_root_kind} eq 'top') {
        ok($decoded->{semantic}{composition}, "$args{entry_id} exposes composition metadata");
    }
    else {
        ok(!exists $decoded->{semantic}{composition}, "$args{entry_id} omits composition metadata for direct roots");
    }

    return $decoded;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
