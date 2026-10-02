use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use FSM::Adapter::ISF::Parser;
use FSM::Test::ConditionalOriginParser;

# Actual counterfactual producer: omit only identity transport across canonical
# rewrites. The real parser still executes; absence must not become guessed intent.
my $json = JSON::PP->new->canonical;
my $base = 'docs/audits/conditional-macro-intent-20261002';
my $cases = $json->decode(read_file("$base/cases.json"));
{
    no warnings 'redefine';
    local *FSM::Test::ConditionalOriginParser::_carry = sub {return $_[2]};
    for my $case (@$cases) {
        my $name = $case->{name};
        my $source = read_file("$base/sources/$name.isf");
        my $ordinary = FSM::Adapter::ISF::Parser->new->parse_source($source, "$name.isf");
        my $parser = FSM::Test::ConditionalOriginParser->new;
        my $actor = eval {$parser->parse_source($source, "$name.isf")};
        my $error = $@;
        ok(defined($actor), "required explicit rewrite association $name") or diag($error);
        write_file(".artifacts/conditional-origin/no-carry/$name.json", $json->encode({
            source => $source, ordinary => $ordinary, instrumented => $actor, error => $error,
            ledger => $parser->ledger,
        }) . "\n");
    }
}
done_testing;
sub read_file {open my $f, '<:raw', $_[0] or die $!; local $/; return <$f>}
sub write_file {open my $f, '>:raw', $_[0] or die $!; print {$f} $_[1] or die $!; close $f or die $!}
