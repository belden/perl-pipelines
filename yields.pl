#!/usr/bin/perl

use strict;
use warnings;

use Yielding;

my $stage = 0;

print join "\n",
	map { "default $stage: $_" }
	grep { $_ % 2 }
	map { $_ + 100 }
	map { $stage++; $_ }
	1..10;
print "\n\n";


$stage = 0;
print join "\n", Yielding->(
	Y::map { "Yielding-> $stage: $_" }
	Y::grep { $_ % 2 }
	Y::map { $_ + 100 }
	Y::map { $stage++; $_ }
	1..5,
	sub { 6..10 },
);
print "\n\n";

$stage = 0;
print join "\n", yielding {
	Y::map { "yielding { $stage: $_" }
	Y::grep { $_ % 2 }
	Y::map { $_ + 100 }
	Y::map { $stage++; $_ }
	1..5,
	sub { 6..10 },
};
print "\n\n";

$stage = 0;
print join "\n", yielding {
	ymap { "yielding again { $stage: $_" }
	ygrep { $_ % 2 }
	ymap { $_ + 100 }
	ymap { $stage++; $_ }
} (1..5, sub { 6..10});
print "\n\n";
