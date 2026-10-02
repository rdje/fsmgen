use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use FSM::Test::DiagnosticCause qw(diagnostic_cause_matches);
use FSM::Test::ConditionalOriginAuthority;
use FSM::Test::SameSourceLibraryOriginParser;
use FSM::Test::LibraryDocumentOriginAuthority;
use FSM::Test::ATLDocumentOriginAuthority;
use FSM::Test::LocalFormalOriginAuthority;

my $json = JSON::PP->new->canonical;
my $fixture = 'docs/audits/source-origin-constructor-causes-20261002';
my $contracts = $json->decode(read_file("$fixture/cause-contracts.json"));
my $saved = $json->decode(read_file("$fixture/products.json"));
my @cases = grep {$_->{band} eq 'positive'} @{$saved->{products}};
is(scalar @cases, 11, 'complete qualified constructor context cohort');
is_deeply([sort map {$_->{id}} @cases], [sort keys %$contracts],
    'every independently declared whole cause has a real producer');
my @products;
for my $case (@cases) {
    subtest "complete constructor cause $case->{id}" => sub {
        my $expected = $contracts->{$case->{id}};
        for my $band (qw(positive wrong_source_echo wrong_source_plain wrong_label_echo)) {
            my $source = $band eq 'positive' ? $case->{source}
                : $band eq 'wrong_source_echo' ? "; $expected\n(not_actor)" : '(not_actor)';
            my $label = $band eq 'positive' ? $case->{label}
                : $band eq 'wrong_label_echo' ? "$expected.isf" : 'wrong.isf';
            # The failing producer receives only its real source arguments.
            my $accepted = eval {construct($case->{kind}, $source, $label); 1};
            my $error = $@;
            ok(!$accepted, "$band actually refuses");
            my $matched = diagnostic_cause_matches($error, $expected);
            if ($band eq 'positive') {
                ok($matched, 'complete independently declared cause matches');
            } else {
                is((split /\n/, $error)[0], "Error: no (actor ...) root found in '$label'",
                    'unrelated actual primary cause is explicit');
                ok(!$matched, "$band cannot authenticate the wanted cause");
            }
            push @products, {id => $case->{id}, band => $band, kind => $case->{kind},
                source => $source, label => $label, expected => $expected,
                accepted => $accepted ? 1 : 0, matched => $matched, error => $error};
        }
    };
}
if (my $capture = $ENV{FSMGEN_CONSTRUCTOR_CAUSE_CAPTURE}) {
    open my $out, '>:raw', "$capture/causes.json" or die $!;
    print {$out} $json->encode(\@products) . "\n" or die $!;
    close $out or die $!;
}
done_testing;

sub construct {
    my ($kind, $source, $label) = @_;
    return FSM::Test::ConditionalOriginAuthority->from_source($source, $label) if $kind eq 'local';
    return FSM::Test::SameSourceLibraryOriginParser->new->parse_source($source, $label) if $kind eq 'same';
    return FSM::Test::LibraryDocumentOriginAuthority->from_documents($label, {$label => $source}, []) if $kind eq 'library';
    return FSM::Test::ATLDocumentOriginAuthority->from_documents($label, {$label => $source}, []) if $kind eq 'ATL';
    return FSM::Test::LocalFormalOriginAuthority->from_source($source, $label) if $kind eq 'formal';
    die "unknown constructor fixture kind $kind";
}
sub read_file {
    open my $file, '<:raw', $_[0] or die $!;
    local $/;
    my $bytes = <$file>;
    close $file or die $!;
    return $bytes;
}
