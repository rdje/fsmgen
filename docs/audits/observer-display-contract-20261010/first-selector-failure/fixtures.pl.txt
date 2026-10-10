use strict;
use warnings;
use JSON::PP ();
use Carp ();
use Scalar::Util qw(blessed refaddr reftype dualvar);
use overload ();

package ObserverDisplayFixture::Plain;
sub new { bless {}, shift }

package ObserverDisplayFixture::Traced;
sub new { bless {}, shift }
sub CARP_TRACE { return 'own-trace-token' }

package ObserverDisplayFixture::Overloaded;
use overload '""' => sub { 'own-overloaded-token' }, fallback => 1;
sub new { bless {}, shift }

package ObserverDisplayFixture;
sub emitter { return Carp::longmess("observer-display-message\n") }
sub boundary { return emitter(@_) }

package main;
my $path = shift @ARGV;
die "one catalogue required\n" unless defined($path) && !@ARGV;
open my $input, '<:raw', $path or die "cannot read catalogue: $!\n";
local $/;
my $catalogue = JSON::PP->new->utf8->decode(<$input>);
close $input or die "cannot close catalogue: $!\n";

sub profile {
    return {
        arg_len => 0 + $Carp::MaxArgLen,
        arg_nums => 0 + $Carp::MaxArgNums,
        eval_len => 0 + $Carp::MaxEvalLen,
        formatter => defined($Carp::RefArgFormatter) ? 'defined' : 'undef',
    };
}
sub scalar_text {
    my ($recipe) = @_;
    my $text = join('', map { chr($_) } @{$recipe->{codepoints}});
    utf8::upgrade($text) if $recipe->{utf8};
    return $text;
}
sub argument {
    my ($recipe, $holders) = @_;
    my $kind = $recipe->{kind};
    return undef if $kind eq 'undef';
    return scalar_text($recipe) if $kind eq 'string';
    return 0 + $recipe->{value} if $kind eq 'number';
    return dualvar($recipe->{number}, scalar_text($recipe)) if $kind eq 'dual';
    return $holders->{$recipe->{target}} if $kind eq 'alias';
    my $value;
    if ($kind eq 'HASH') { $value = {} }
    elsif ($kind eq 'ARRAY') { $value = [] }
    elsif ($kind eq 'CODE') { $value = sub { 'own-code' } }
    elsif ($kind eq 'REGEXP') { my $pattern = scalar_text($recipe); $value = qr/$pattern/ }
    elsif ($kind eq 'plain') { $value = ObserverDisplayFixture::Plain->new }
    elsif ($kind eq 'traced') { $value = ObserverDisplayFixture::Traced->new }
    elsif ($kind eq 'overloaded') { $value = ObserverDisplayFixture::Overloaded->new }
    else { die "unknown argument kind $kind\n" }
    $holders->{$recipe->{id}} = $value;
    return $value;
}
sub view {
    my ($value) = @_;
    return {kind => 'undef'} unless defined $value;
    if (ref $value) {
        return {
            kind => 'reference', type => reftype($value), class => blessed($value),
            address_hex => sprintf('0x%x', refaddr($value)),
            fallback => overload::StrVal($value), text => "$value",
        };
    }
    return {kind => 'scalar', codepoints => [map { ord($_) } split(//, "$value")],
            utf8 => utf8::is_utf8($value) ? JSON::PP::true : JSON::PP::false};
}

my $initial = profile();
my @observations;
for my $case (@{$catalogue->{cases}}) {
    my %holders;
    my @args = map { argument($_, \%holders) } @{$case->{arguments}};
    local $Carp::MaxArgLen = defined($case->{profile}{arg_len}) ? $case->{profile}{arg_len} : $Carp::MaxArgLen;
    local $Carp::MaxArgNums = defined($case->{profile}{arg_nums}) ? $case->{profile}{arg_nums} : $Carp::MaxArgNums;
    local $Carp::RefArgFormatter = $case->{profile}{formatter}
        ? sub { 'own-reference-formatter-token' } : undef;
    my $before = [map { view($_) } @args];
    my $selected = profile();
    my $text = ObserverDisplayFixture::boundary(@args);
    my $after = [map { view($_) } @args];
    push @observations, {id => $case->{id}, profile => $selected,
                         before => $before, after => $after, text => $text};
}
print JSON::PP->new->canonical->utf8->encode({
    role => 'Own current public display fixtures; original formatter/settings/provider identity is unmeasured.',
    versions => {perl => "$^V", Carp => ''.Carp->VERSION, JSON_PP => ''.JSON::PP->VERSION,
                 Scalar_Util => ''.Scalar::Util->VERSION, overload => ''.overload->VERSION},
    initial => $initial, observations => \@observations,
}), "\n";
