use strict;
use warnings;
use lib 'perl';
use Test::More;
use File::Path qw(make_path);
use IPC::Open3 qw(open3);
use Symbol qw(gensym);
use JSON::PP qw(encode_json);
use FSM::ProjectDataLocality qw(create_project_tempdir);

sub put {
    my ($root, $path, $bytes) = @_;
    open my $out, '>', "$root/$path" or die $!;
    print {$out} $bytes; close $out or die $!;
}
sub read_file {
    open my $in, '<', $_[0] or die $!; local $/; return <$in>;
}
sub fixture {
    my $root = create_project_tempdir(purpose => 'live-adapter-sharing');
    make_path("$root/bin");
    my %records = (
        surfaces => [
            {surface_id => 'first', verifier => 'adapter:bin/check'},
            {surface_id => 'second', verifier => 'adapter:bin/check',
                currency => {contract_id => 'current', verifier => 'adapter:bin/check'}},
            {surface_id => 'other', verifier => 'adapter:bin/other'},
        ],
        derived => [{record_type => 'contract', storage => 'verified_copy',
            contract_id => 'copy', verifier => 'adapter:bin/check'}],
        archives => [{record_type => 'descriptor', retrieval_kind => 'version_object',
            descriptor_id => 'saved', verifier => 'adapter:bin/check'}],
        ledgers => [{record_type => 'ledger', ledger_id => 'entries',
            reconstruction_verifier => 'adapter:bin/check'}],
    );
    for my $kind (keys %records) {
        put($root, "$kind.jsonl", join('', map {encode_json($_) . "\n"} @{$records{$kind}}));
    }
    for my $name (qw(check other)) {
        put($root, "bin/$name", <<'SCRIPT');
#!/bin/sh
printf '%s\n' "${0##*/}" >> invocations
read -r verdict < verdict
[ "$verdict" = PASS ]
SCRIPT
        chmod 0755, "$root/bin/$name" or die $!;
    }
    put($root, 'verdict', "PASS\n");
    return $root;
}
sub run {
    my ($root, @extra) = @_;
    my $error = gensym;
    my $pid = open3(undef, my $out, $error, $^X,
        'scripts/run_live_document_adapter_verifiers.pl', '--root', $root,
        '--registry', 'surfaces.jsonl', '--archives', 'archives.jsonl',
        '--ledgers', 'ledgers.jsonl', '--derived-state', 'derived.jsonl', @extra);
    my $proofs = do {local $/; <$out> // ''};
    my $errors = do {local $/; <$error> // ''};
    waitpid($pid, 0); return ($? == 0, [split /\n/, $proofs], $errors);
}
my @proofs = qw(surface:first surface:second surface:other currency:second
    derived:copy archive:saved ledger:entries);
my $root = fixture();
my ($ok, $proof, $errors) = run($root);
ok($ok, 'default adapter execution passes') or diag($errors);
is_deeply($proof, \@proofs, 'all distinct proof obligations emitted');
is(read_file("$root/invocations"), "check\ncheck\nother\ncheck\ncheck\ncheck\ncheck\n", 'standalone default executes every role');
unlink "$root/invocations" or die $!;
($ok, $proof, $errors) = run($root, '--share-read-only-verifiers');
ok($ok, 'explicit read-only sharing passes') or diag($errors);
is_deeply($proof, \@proofs, 'sharing preserves all exact proof tokens');
is(read_file("$root/invocations"), "check\nother\n", 'equivalent commands execute once; distinct paths with identical bytes execute separately');
like($errors, qr/shared execution for archive:saved/, 'shared physical execution is visible without polluting proof tokens');
my @before = stat "$root/verdict";
put($root, 'verdict', "FAIL\n"); utime $before[8], $before[9], "$root/verdict" or die $!;
is(-s "$root/verdict", $before[7], 'changed input preserves size');
is((stat("$root/verdict"))[9], $before[9], 'changed input preserves whole-second mtime');
($ok, $proof, $errors) = run($root, '--share-read-only-verifiers');
ok(!$ok, 'fresh invocation rejects changed input after prior success');
is_deeply($proof, [], 'failure emits no successful proof');
like($errors, qr/failed \(exit 1\) for surface:first/, 'failure retains exact first obligation');
my $other = fixture();
($ok, $proof, $errors) = run($other, '--share-read-only-verifiers');
ok($ok, 'other root validates independently') or diag($errors);
is(read_file("$other/invocations"), "check\nother\n", 'distinct root has actual executions');
unlink "$other/bin/check" or die $!;
($ok, $proof, $errors) = run($other, '--share-read-only-verifiers');
ok(!$ok, 'missing executable cannot reuse a previous proof');
like($errors, qr/absent or not executable/, 'missing executable diagnostic retained');
done_testing();
