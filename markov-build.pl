#!/usr/bin/perl
use warnings;
use strict;
use utf8;

use FindBin qw($Bin);
use Encode;
use MeCab;
use DBD::SQLite;

binmode STDIN, ':encoding(utf8)';
binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';

my $dbh = DBI->connect(
	'dbi:SQLite:dbname=' . $Bin . '/db/markov.db', '', '', {unicode => 1});

my $m = new MeCab::Tagger;

printf STDERR "Generating words table ...\n";
while(<STDIN>)
{
	next if /^[\r\n\s]*$/;
	next if /^\-\-/;
	next if /htt/;

	s/[☆★]{2,}//g;
	s/={3,}//g;

	my $line = $_;

	my $sth = $dbh->prepare(
			'INSERT INTO words (word, pos) VALUES (?, ?)');
	my $sth_states = $dbh->prepare(
			'INSERT INTO states (wid, next) VALUES (?, ?)');

	my @words = ();

	my $n = $m->parseToNode(encode('utf8', $line));
	#while($n->{next})
	while($n)
	{
		my $surface = decode('utf8', $n->{surface});
		my $feature = decode('utf8', $n->{feature});

		$feature = join(',', (split(/,/, $feature))[0..2]);

		printf("%s : %s\n", $surface, $feature);

		$sth->execute($surface, $feature);

		my $s = $dbh->prepare('SELECT * FROM words WHERE word = ? AND pos = ?');
		$s->execute($surface, $feature);
		my $word = $s->fetchrow_hashref;
		push(@words, $word);

		if($#words >= 1)
		{
			my $state = shift(@words);
			print $state->{word} . " -> " . $word->{word} . "\n";
			$sth_states->execute($state->{id}, $word->{id});
		}

		$n = $n->{next}; # 次に移動
	}
	$sth->finish;
	$sth_states->finish;
}

$dbh->disconnect;

# vim: noexpandtab
