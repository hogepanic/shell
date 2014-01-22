#!/usr/bin/perl

my $logpath = $ARGV[0];
open(LOGFILE, $logpath) || die $!;


while (<LOGFILE>) {

  /^"(.*)"	"(.*)"	"(.*)"	"(.*)"	"(.*)"	"(.*)"	"(.*)"	"(.*)"/;

  $datetime = $1;
  $page = $2;
  $pageid = $3;
  $tpl = $4;
  $useragent = $5;
  $viewerid = $6;
  $param = $7;
  $naiyou = $8;

  print $datetime;
  print "\t";
  print $pageid;
  print "\t";
  print $viewerid;
  print "\n";
}

close(LOGFILE);

exit;
