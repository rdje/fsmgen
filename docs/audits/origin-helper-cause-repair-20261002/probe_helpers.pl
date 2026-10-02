use strict;
use warnings;
use JSON::PP;
use FSM::Test::DiagnosticCause ();
my $json = JSON::PP->new->canonical;
my $input = $json->decode(do {local $/; <STDIN>});
delete @ENV{qw(FSMGEN_LIBRARY_DIAGNOSTIC_FULL_STACK FSMGEN_FILE_DIAGNOSTIC_FULL_STACK)};
my %results;
for my $kind (qw(library file)) {
    my $old = 'Old' . ucfirst($kind);
    my $current = 'Current' . ucfirst($kind);
    eval "package $old;" . $input->{$kind}{old}; die $@ if $@;
    eval "package $current; use FSM::Test::DiagnosticCause qw(diagnostic_cause_matches);" . $input->{$kind}{current}; die $@ if $@;
    my $error = $input->{$kind}{product}{error};
    my $expected = $input->{$kind}{product}{expected};
    my $pattern = qr/selected source bytes differ/;
    no strict 'refs';
    $results{$kind} = {old => &{"${old}::diagnostic_matches"}($error, $pattern),
        current => &{"${current}::diagnostic_matches"}($error, $expected)};
}
print $json->encode(\%results), "\n";
