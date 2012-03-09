package yielding;
use base qw(Exporter);

use strict;
use warnings;

our @EXPORT = qw(Yielding yielding ymap ygrep yapply);

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

				($arg) = @got if $mode ne 'apply';
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
sub ::ymap(&@);
*ymap = \&Y::map;
*::ymap = \&Y::map;


sub Y::grep(&@) {
	my $code = shift;
	return __PACKAGE__->new(grep => $code), @_;
}
sub ygrep(&@);
sub ::ygrep(&@);
*ygrep = \&Y::grep;
*::ygrep = \&Y::grep;

sub Y::apply(&@) {
	my $code = shift;
	return __PACKAGE__->new(apply => $code), @_;
}
sub yapply(&@);
sub ::yapply(&@);
*yapply = \&Y::apply;
*::yapply = \&Y::apply;

sub new {
	my ($class, $mode, $code) = @_;
	return bless +{
		grep => sub {
			$yielding::mode = $mode;
			return grep { $code->($_) } @_;
		},
		map => sub {
			$yielding::mode = $mode;
			return map { $code->($_) } @_;
		},
		apply => sub {
			$yielding::mode = $mode;
			$code->() foreach @_;
			return @_;
		},
	}->{$mode}, $class;
}

1;

__END__

=pod

=head1 NAME

yielding - add yielding to your perl

=head1 SYNOPSIS

	use yielding;

	my @output = yielding {
		ymap    { ... }
		ygrep   { ... }
		yapply  { ... }
	} (1..10);

=head1 DESCRIPTION

If your language doesn't implement it, fake it. This module allows you to turn Perl's normal
batched data transformation into a yieldable execution pipeline. All code which C<use yielding>
get a C<yielding> function, and associated yieldable C<map> and C<grep> functions.

Consider this code:

	my $stage = 0;
	print join "\n",
		map { "$stage: $_" }
		grep { $_ % 2 }
		map { $_ + 100 }
		map { $stage++; $_ }
		1..10;

The output is:

	10: 101
	10: 103
	10: 105
	10: 107
	10: 109

Note the leading "10" on all of those lines. This tells us that the code above is analogous to:

	my $stage = 0;
	my @data    = map { $stage++; $_ } (1..10);
	my @plus100 = map { $_ + 100 } @data;
	my @odds    = grep { $_ % 2 } @plus100;
	my @output  = map { "$stage: $_" } @odds;
	print join "\n", @output;

That is, each stage of transformation operates over the entire set of input before returning
its output to the next stage of transformation.

Sometimes code which is written using chains of C<map>, C<grep>, and C<apply> can be thought of
as idempotent actions on each member of input. C<yielding> allows you to express the above code
like so:

	my $stage = 0;
	print join "\n", yielding {
		ymap  { "$stage: $_" }
		ygrep { $_ % 2 }
		ymap  { $_ + 100 }
		ymap  { $stage++; $_ }
	} (1..10);

Which produces as output:

	1: 101
	3: 103
	5: 105
	7: 107
	9: 109

Here, the leading 1, 3, 5, 7, and 9 indicate that the *stages of transformation* were treated
as a batched operation, which each member of input was passed through. The above code is
roughly analogous to:

	my $stage = 0;
	my @out;
	foreach $_ (1..10) {
		$stage++;
		next unless $_ % 2;
		$_ += 100;
		push @out, "$stage: $_";
	}
	print join "\n", @out;

There are a few alternate ways to write the C<yielding> statement above:

	my $stage = 0;
	print join "\n", Yielding->(
		ymap { "$stage: $_" }
		ygrep { $_ % 2 }
		ymap { $_ + 100 }
		ymap { $stage++; $_ }
		1..10,
	);

C<yielding> can be called in a similar fashion, i.e. with its args after the execution pipeline:

	my $stage = 0;
	print join "\n", yielding {
		ymap { "$stage: $_" }
		ygrep { $_ % 2 }
		ymap { $_ + 100 }
		ymap { $stage++; $_ }
		1..10,
	};

Any coderefs in the args to C<yielding> or C<Yielding> will be treated as generators for producing
additional args to process:

	my $stage = 0;
	print join "\n", yielding {
		ymap { "$stage: $_" }
		ygrep { $_ % 2 }
		ymap { $_ + 100 }
		ymap { $stage++; $_ }
		(1..3),
		sub { 4..7 },
		(8..10)
	};

=head1 EXPORTS

=over 4

=item *

ymap BLOCK

Make a yieldable C<map> call for BLOCK. BLOCK will be called for each item of input. The item is
available in $_. The return value of C<ymap> will become the input value for the next stage in
your execution pipeline.

=item *

ygrep BLOCK

Make a yieldable C<grep> call for BLOCK. BLOCK will be called for each item of input. The item is
available in $_. Like Perl's C<grep>, returning a true value will allow this item of input to
continue through the execution pipeline; returning a false value will filter this item out.

=item *

yapply BLOCK

Make a yieldable C<apply> call for BLOCK. The return value of BLOCK is ignored; mutations to $_
become the next piece of input for the execution pipeline.

=item *

yielding BLOCK
yielding BLOCK LIST

Given a BLOCK of yieldable statements, C<yielding> manages your LIST of input through the execution
pipeline. If LIST is not given, BLOCK should end with a LIST of input:

	yielding {                # start of BLOCK
		ygrep { $_ % 2 }        # yieldable statement (a fairly lame execution pipeline)
		1..10                   # LIST of input
	};                        # end  of BLOCK

Both BLOCK and LIST may contain input. In this case, the input at the end of BLOCK will be processed
before the input of LIST. For example, to see all the odd numbers between 1 and 20, one could write:

	print join "\n", yielding {
		ygrep { $_ % 2 }
		1..10
	} 11..20;

=item *

Yielding->(LIST)

Returns a code reference which you can fill with your yieldable calls and immediately execute:

	my @output = Yielding->(
		ymap  { send_data_across_network(@_) }
		ygrep { is_data_we_care_to_transmit(@_) }
		\&load_data_from_store,
	);

The return value of C<Yielding>'s return value is the output of your execution pipeline. In the
example above, @output would be filled with whatever C<send_data_across_network()>'s return value
is.

=back

=head1 BUGS

Absolutely none whatsoever. (Code which is not in use has no bugs.)

=head1 RATIONALE

This seemed like a good idea at the time.

=head1 AUTHOR

Belden Lyman <belden@cpan.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
