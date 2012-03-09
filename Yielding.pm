package Yielding;
use base qw(Exporter);

use strict;
use warnings;

our @EXPORT = qw(Yielding yielding ymap ygrep);

our $mode = '';
sub Yielding {
	return sub {

		my @stages = grep { ref($_) && UNIVERSAL::isa($_, __PACKAGE__) } reverse(@_);
		my %stages = map { ("$_" => 1) } @stages;
		my @args = grep { ! exists $stages{$_} } @_;

		my @out;
	ARG:
		while (my $arg = shift @args) {
			if (ref($arg) eq 'CODE') {
				unshift @args, $arg->();
				next ARG;
			}

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

sub yielding (&@) {
	my $code = shift;
	return Yielding->($code->(), @_);
}

sub Y::map(&@) {
	my $code = shift;
	return __PACKAGE__->new(map => $code), @_;
}
sub ymap(&@);
*ymap = \&Y::map;


sub ygrep(&@);
sub Y::grep(&@) {
	my $code = shift;
	return __PACKAGE__->new(grep => $code), @_;
}
*ygrep = \&Y::grep;

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
