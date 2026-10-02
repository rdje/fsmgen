use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use FSM::Test::LibraryDocumentOriginAuthority;

my $base = 'docs/audits/source-origin-refusal-review-20261002';
my (@bindings, @results);
for my $case (
    ['library', 't/2046-isf-library-document-origin-authority.t', 'SourceReview::Library', 'rejected'],
    ['file', 't/2048-isf-file-document-origin-authority.t', 'SourceReview::File', 'refuses'],
) {
    my ($kind, $path, $package, $function) = @$case;
    my $source = read_file($path);
    my @functions = $kind eq 'file' ? ($function, 'diagnostic_line', 'diagnostic_matches') : ($function);
    my @bodies;
    for my $name (@functions) {
        my ($body) = $source =~ /^(sub \Q$name\E[^\n]*\})/m;
        ($body) = $source =~ /^(sub \Q$name\E \{.*?^\})/msg unless defined $body;
        die "missing exact helper $name in $path" unless defined $body;
        push @bodies, $body;
    }
    my $program = "package $package; use strict; use warnings; use Test::More;\n"
        . join("\n", @bodies) . "\n";
    eval $program; die $@ if $@;
    push @bindings, {path => $path, source_sha256 => sha256_hex($source), bodies => \@bodies};
    no strict 'refs';
    my $consumer = \&{"${package}::$function"};
    for my $mode (qw(wrong_echo correct)) {
        my $pattern = $mode eq 'wrong_echo' ? qr/source_review_reason_only_in_caller/
            : qr/library origin independent document set required/;
        my (@controls, $error);
        my $callback = sub {
            eval {FSM::Test::LibraryDocumentOriginAuthority->from_documents('missing.isf', {}, [])};
            $error = $@;
            die $error;
        };
        if ($kind eq 'library') {
            $consumer->($callback, $pattern, "$kind-$mode");
        } else {
            $consumer->("$kind-$mode", $callback, $pattern, \@controls);
        }
        my ($first) = split /\n/, $error;
        push @results, {kind => $kind, mode => $mode, error => $error, first_line => $first,
            first_line_matches => $first =~ $pattern ? 1 : 0,
            full_trace_matches => $error =~ $pattern ? 1 : 0, controls => \@controls};
    }
}
open my $output, '>', "$base/helper-products.json" or die $!;
print {$output} JSON::PP->new->canonical->encode({bindings => \@bindings, results => \@results}) . "\n";
close $output or die $!;
done_testing;

sub read_file {open my $file, '<:raw', $_[0] or die $!; local $/; return <$file>}
