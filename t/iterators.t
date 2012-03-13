#!/usr/bin/perl

use strict;
use warnings;

use Test;
BEGIN { plan tests => 4 }

use lib '../lib';
use yielding;

{
	package iterator;

	sub new {
		my ($class, @records) = @_;
		return bless \@records, $class;
	}

	sub next {
		my ($self) = @_;
		my $rec = shift @$self;
		return defined $rec ? $rec : undef;
	}

	sub terminate {
		my ($self) = @_;
		@{$self} = ();
		return;
	}
}

my $iterator = iterator->new(11..59);

my $numbers = join ',', yielding { (1..10, $iterator, 60..100) };
ok( $numbers, join(',', 1..100) );

# let's calculate some primes
sub prime { # eh, prime enough
	return 1 if $_ < 4;
	return 0 if $_ % 2 == 0 || $_ % 3 == 0 || int(sqrt($_))**2 == $_;
	return 1;
}
my $prime = join ',', yielding { ygrep { prime } iterator->new(1..20) };
ok( $prime, join(',', (1,2,3,5,7,11,13,17,19)) );
