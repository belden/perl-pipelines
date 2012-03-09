#!/usr/bin/perl

use strict;
use warnings;

use yielding;

my $stage = 0;

print join "\n",
	map { "$stage: $_" }
	grep { $_ % 2 }
	map { $_ + 100 }
	map { $stage++; $_ }
	1..10;
print "\n\n";

$stage = 0;
my @out;
foreach $_ (1..10) {
	$stage++;
	next unless $_ % 2;
	$_ += 100;
	push @out, "$stage: $_";
}
print join "\n", @out;
print "\n\n";


$stage = 0;
print join "\n", Yielding->(
	Y::map { "Yielding-> $stage: $_" }
	Y::grep { $_ % 2 }
	Y::apply { $_ += 200; 'a' }
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
	ymap  { "yielding again { $stage: $_" }
	ygrep { $_ % 2 }
	ymap  { $_ + 100 }
	ymap  { $stage++; $_ }
} (1..10);
print "\n\n";

$stage = 0;
print join "\n", yielding {
	::ymap  { "yielding yet again { $stage: $_" }
	::ygrep { $_ % 2 }
	::ymap  { $_ + 100 }
	::ymap  { $stage++; $_ }
} (1..10);
print "\n\n";

$stage = 0;
print join "\n", yielding {
	ymap { "yielding with generators { $stage: $_" }
	ygrep { $_ % 2 }
	ymap { $_ + 100 }
	ymap { $stage++; $_ }
} (1..5, sub { 6..10});
print "\n\n";
