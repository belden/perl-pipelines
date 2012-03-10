#!/usr/bin/perl

use strict;
use warnings;

use Test;
BEGIN { plan tests => 3 }

use lib '../lib';
use yielding;

sub hok {
	my ($got, $heredoc) = @_;
	chomp $heredoc;
	local $Test::TestLevel = $Test::TestLevel + 1;
	ok( $got, $heredoc );
}

# basic test of yieldable map/grep/apply
my $stage = 0;
my $got = join "\n", yielding {
	ymap { "$stage: $_" }
	yapply { s/([aeiou])/uc $1/ge }
	ygrep { /^\d/ }
	ymap { $stage++; $_ }
	('apple', '2 bananas', '4 cherimoya', '8 durian')
};

hok( $got, <<EXPECTED );
2: 2 bAnAnAs
3: 4 chErImOyA
4: 8 dUrIAn
EXPECTED

# args can appear inside and outside the block - set ourselves up
# to easily prove this.
my @block_args;
my @list_args;
my $pipeline = sub {
	yielding {
		ymap  { "$stage: $_" }
		ygrep { $_ % 2 }
		yapply  { $_ += 100; 'a' }
		ymap  { $stage++; $_ }
		@block_args
	} @list_args;
};

# first, args inside the block
$stage = 0;
@block_args = (1..10);
@list_args = ();
$got = join "\n", $pipeline->();
hok( $got, <<EXPECTED );
1: 101
3: 103
5: 105
7: 107
9: 109
EXPECTED

# now, args inside and outside the block; notice args inside the block
# are processed before args outside the block.
$stage = 0;
@block_args = (1..5);
@list_args = (6..10);
$got = join "\n", $pipeline->();
hok( $got, <<EXPECTED );
1: 101
3: 103
5: 105
7: 107
9: 109
EXPECTED

# args which are coderefs are understood to be generators of new args
$stage = 0;
@block_args = (
	sub { 1..3 },
	sub { 4..5 },
);
@list_args = (
	sub { 6..8 },
	sub { 9..10 },
);
$got = join "\n", $pipeline->();
hok( $got, <<EXPECTED );
1: 101
3: 103
5: 105
7: 107
9: 109
EXPECTED
