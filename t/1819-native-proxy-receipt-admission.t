#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../docs/audits/native-proxy-receipt-admission-20260922";

# Keep the no-process admission controls in ordinary test discovery as well as
# at their recorded audit entrypoint. The fixture intercepts process primitives
# before loading Admission.pm, so an accidental launch fails the test.
require "$FindBin::Bin/../docs/audits/native-proxy-receipt-admission-20260922/qualify.t";
