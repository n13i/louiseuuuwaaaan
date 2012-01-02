#!/usr/bin/perl
use warnings;
use strict;
use utf8;

use FindBin qw($Bin);
use Encode;
use DBD::SQLite;
use Net::Twitter::Lite;
use YAML;
use DateTime;

binmode STDIN, ':encoding(utf8)';
binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';

my $conffile = $Bin . '/conf/config.yaml';
my $conf = YAML::LoadFile($conffile) or die('load config failed');

my $dt_now = DateTime->now(time_zone => $conf->{timezone});
printf "Now: %s\n", $dt_now->strftime('%Y/%m/%d %H:%M:%S');

my $twit = Net::Twitter::Lite->new(
	consumer_key => $conf->{twitter}->{consumer_key},
	consumer_secret => $conf->{twitter}->{consumer_secret},
);
$twit->access_token($conf->{twitter}->{access_token});
$twit->access_token_secret($conf->{twitter}->{access_token_secret});

my $dbh = DBI->connect(
	'dbi:SQLite:dbname=' . $Bin . '/db/markov.db', '', '', {sqlite_unicode => 1});

my $post = '';
for(my $i = 0; $i < 3; $i++)
{
	$post = &generate;
	last if(length($post) != 0);
	printf "retry %d\n", $i+1;
}
if(length($post) != 0)
{
	# morning shot hack
	#if(($dt_now->hour == 6 && $dt_now->minute == 0) ||
	#   ($ARGV[0] || '') eq 'test')
	if(($ARGV[0] || '') eq 'test')
	{
		$post =~ s/(ルイズ|スーハー|クンカ|コミック|小説|アニメ)/朝チュン/g;
		$post =~ s/フランソワーズ/モーニング/g;
		$post =~ s/(匂い|ハルケギニア|髪|カリ)/朝/g;
		$post =~ s/(モフ)/チュン/g;
		$post =~ s/(くん)/ちゅん/g;
		$post =~ s/桃色/朝焼け/g;
		$post =~ s/ブロンド/オレンジ/g;
		$post =~ s/世の中/夜中/g;
		$post =~ s/捨てた/明けた/g;
		$post =~ s/現実/睡眠/g;
		$post =~ s/ケティ/モーニング/g;
		$post =~ s/アン様/お日様/g;
		$post =~ s/(セ、|シ、)/あ、/g;
		$post =~ s/(セイバー|シエスタ)/朝/g;
		$post =~ s/(シャナ|アンリエッタ)/朝/g;
		$post =~ s/(ヴィルヘルミナ|タバサ)/朝/g;
		$post =~ s/サイト/夕方/g;
	}
	elsif(($ARGV[0] || '') eq 'test3')
	{
		$post =~ s/ルイズ/まいん/g;
		$post =~ s/・フランソワーズ//g;
		$post =~ s/サイト/DJソルト/g;
		$post =~ s/挿絵/NHK教育/g;
		$post =~ s/2期/再放送/g;
		$post =~ s/表紙絵/テレビ/g;
	}
	elsif(rand() < 0.05 || ($ARGV[0] || '') eq 'test2')
	{
		$post =~ s/！/…/g;
	}

	print $post . "\n";
	print "length = " . length($post) . "\n";

	if(($ARGV[0] || '') !~ /^test/)
	{
		eval {
			my $status = $twit->update($post);
			print Dump($status);
		};
	}
}

$dbh->disconnect;


sub generate
{
	my $state = $dbh->selectrow_hashref(
		"SELECT * FROM words ws WHERE ws.pos LIKE 'BOS%' " .
		"ORDER BY RANDOM() LIMIT 1");
#	printf STDERR "%d: %s : %s\n", $state->{id}, $state->{word}, $state->{pos};

	my @sentences = ();
	my $s = '';
	my $len = 0;
	for(my $i = 0; $i < 1000; $i++)
	{
		$s .= $state->{word};

		# 現在の状態から次の状態を探す

#		printf STDERR "%d: generating candidates ... ", $i;
		my $sth = $dbh->prepare(
			'SELECT w.id AS id, w.word AS word, w.pos AS pos ' .
			'FROM words w, states s ' .
			'WHERE w.id = s.next AND s.wid = ? ' .
			'ORDER BY RANDOM() LIMIT 1');
		$sth->execute($state->{id});
		my $next = $sth->fetchrow_hashref;

		if(!defined($next))
		{
			# 残りの state も追加
			push(@sentences, $s);
			$s = '';
			last;
		}

#		printf STDERR "%s | %s\n", $next->{word}, $next->{pos};

		if($next->{pos} =~ /^BOS/)
		{
			# 残りの state も追加
			push(@sentences, $s);
			$len += length($s);
			$s = '';
			if($len > 140)
			{
				pop(@sentences);
				last;
			}
			last if(rand() < ($len/140.0)*0.9);
		}

		$state = $next;
	}

	my $r = join('', @sentences);
	return $r;
}

# vim: noexpandtab
