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
print "\n";


$stage = 0;
print join "\n", Yielding->(
	sub { map { "$stage: $_" } @_ },
	sub { grep { $_ % 2 } @_ },
	sub { map { $_ + 100 } @_ },
	sub { map { $stage++; $_ } @_ },
	1..10
);
print "\n";
