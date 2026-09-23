#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin", "$FindBin::Bin/../../../perl", "$FindBin::Bin/../../../t/lib",
    "$FindBin::Bin/../native-proxy-receipt-admission-20260922",
    "$FindBin::Bin/../native-proxy-receipt-adapter-20260922",
    "$FindBin::Bin/../native-proxy-compiler-census-policy-admission-20260913";
use Capture;

die "usage: capture.pl --execute-admitted CLEAN_HEAD_SHA\n"
    unless @ARGV == 2 && $ARGV[0] eq '--execute-admitted';
NativeProxyReceiptCapture::run_capture($ARGV[1]);
print "compiler receipt captured; review the retained first state before further work\n";
