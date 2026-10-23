package FSMGen::PodHTML;
use v5.20;
use strict;
use warnings;
use parent 'Pod::Simple::HTML';

# These are this renderer's own attributes, not Pod::Simple implementation state.
our (%MODULES, %PROVIDED, %ENTRYPOINTS);

sub batch_mode_page_object_init {
    my ($self, $batch, $module, $infile, $outfile, $depth) = @_;
    die "Unclassified POD module: $module\n" unless $MODULES{$module};
    my @parts = split /::/, $module;
    my $prefix = '../' x (@parts - 1);
    $self->{fsmgen_api_prefix} = $prefix;
    my $kind = exists $ENTRYPOINTS{$module}
        ? 'Selected entry point: consult the published contract for its stability boundary.'
        : 'Implementation documentation. This page does not promise a supported external API.';
    my $source = 'perl/' . join('/', @parts) . '.pm';
    $self->html_header_before_title('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>');
    $self->html_header_after_title(qq{</title><link rel="stylesheet" href="${prefix}reference.css"></head><body><nav aria-label="Reference navigation"><a href="${prefix}index.html">API index</a><a href="${prefix}../11-extensions-and-embedding.html">FSMGen manual</a></nav><main><p class="boundary">$kind</p><p class="source">Source: <code>$source</code></p>});
    $self->html_footer('</main><footer>Generated from repository POD with Pod::Simple::HTMLBatch.</footer></body></html>');
}

sub do_pod_link {
    my ($self, $link) = @_;
    my $to = $link->attr('to') // '';
    if ($to =~ /\AFSM::/) {
        die "POD links to an unknown FSM module: $to\n" unless $MODULES{$to};
        die "POD links to a section of an undocumented module: $to\n"
            if !$PROVIDED{$to} && defined $link->attr('section');
        # Keep the public renderer's fragment spelling, but make every FSM
        # module link local, including explicit no-POD inventory pages.
        my $standard = $self->SUPER::do_pod_link($link);
        my $fragment = defined($standard) && $standard =~ /(#.*)\z/ ? $1 : '';
        (my $path = $to) =~ s{::}{/}g;
        return $self->{fsmgen_api_prefix} . $path . '.html' . $fragment;
    }
    return $self->SUPER::do_pod_link($link);
}

1;
