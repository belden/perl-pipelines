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
	Y::map { "$stage: $_" }
	Y::grep { $_ % 2 }
	Y::map { $_ + 100 }
	Y::map { $stage++; $_ }
	1..5,
	sub { 6..10 },
);
print "\n";
