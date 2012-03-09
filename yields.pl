#!/usr/bin/perl

use strict;
use warnings;

use Yielding;

my $stage = 0;

print join "\n",
	map { "$stage: $_" }
	grep { $_ % 2 }
	map { $_ + 100 }
	map { $stage++; $_ }
	1..10;
print "\n\n";


$stage = 0;
print join "\n", Yielding->(
	ymap { "$stage: $_" },
	ygrep { $_ % 2 },
	ymap { $_ + 100 },
	ymap { $stage++; $_ },
	1..10
);
print "\n";
