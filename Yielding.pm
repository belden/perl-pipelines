package Yielding;
use base qw(Exporter);

use strict;
use warnings;

our @EXPORT = qw(Yielding ymap ygrep);

our $mode = '';
sub Yielding {
	return sub {

		my @stages = grep { ref($_) && $_->isa(__PACKAGE__) } reverse(@_);
		my %stages = map { ("$_" => 1) } @stages;
		my @args = grep { ! exists $stages{$_} } @_;

		my @out;
	ARG:
		foreach my $arg (@args) {
			foreach my $stage (@stages) {
				local $mode;
				my (@got) = $stage->($arg);
				if ($mode eq 'grep' && scalar(@got) == 0) {
					next ARG;
				}
				($arg) = @got;
			}
			push @out, $arg;
		}

		return @out;
	};
}

sub ymap(&) {
	my $code = shift;
	return __PACKAGE__->new(map => $code);
}

sub ygrep(&) {
	my $code = shift;
	return __PACKAGE__->new(grep => $code);
}

sub new {
	my ($class, $mode, $code) = @_;
	return bless +{
		grep => sub {
			$Yielding::mode = $mode;
			return grep { $code->($_) } @_;
		},
		map => sub {
			$Yielding::mode = $mode;
			return map { $code->($_) } @_;
		}
	}->{$mode}, $class;
}

1;
