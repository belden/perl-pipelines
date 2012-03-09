package Yielding;
use base qw(Exporter);

use strict;
use warnings;

our @EXPORT = qw(Yielding);

sub Yielding {
	return sub {
		my @stages = grep { ref($_) eq 'CODE' } reverse(@_);
		my %stages = map { ("$_" => 1) } @stages;
		my @args = grep { ! exists $stages{$_} } @_;
		my @out;
		foreach my $arg (@args) {
			foreach my $stage (@stages) {
				($arg) = $stage->($arg);
			}
			push @out, $arg;
		}
		return @out;
	};
}

1;
