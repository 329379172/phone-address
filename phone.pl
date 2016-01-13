#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use utf8;
use encoding 'utf-8';
use HTTP::Tiny;
use Redis;
use Encode;
use URI::Escape;
use JSON::PP;
use File::Util;
binmode( STDIN, ':encoding(utf8)' );
binmode( STDOUT, ':encoding(utf8)' );
binmode( STDERR, ':encoding(utf8)' );
my @phoneSegment = (
    133,
    153,
    180,
    189,
    181,
    170,
    177,
    134,
    135,
    136,
    137,
    138,
    139,
    150,
    151,
    152,
    157,
    158,
    159,
    178,
    182,
    183,
    184,
    187,
    188,
    130,
    131,
    132,
    155,
    156,
    185,
    186,
    175,
    176,
    145,
    147
);

my $f = File::Util->new();

sub run(@) {
    my (@lines) = $f->load_file('./phone.ls', '--as-lines');
    my $i = my $total = $f->line_count('./phone.ls');
    my $lastLine;
    if ($total > 0) {
        $lastLine = $lines[$i];
        while(!$lastLine || $i < 0){
            $i--;
            $lastLine = $lines[$i];
        }
    }
    my $startSegment;
    my $startIndex;
    my $continue;
    if ($lastLine) {
        my $match = $lastLine =~ /(^\d+)/;
        if ($match) {
            $startSegment = $1;
            my $leng = length($startSegment);
            if ($leng == 7) {
                $startIndex = substr($startSegment, 3, 4);
                $startSegment = substr($startSegment, 0, 3);
                $continue = 1;
            }
        }
    }
    my ($handle) = $f->open_handle(
        file    => './phone.ls',
        mode    => 'append',
        binmode => 'utf8'
    );
    print $handle "\n";
    if ($continue) {
        my $ok;
        foreach my $item (@_) {
            if(!$ok) {
                if($item == $startSegment){
                    $ok = 1;
                }
            }
            if($ok){
                for ($i = $startIndex + 1; $i < 10000; $i++) {
                    my $textline = getAddr($item * 10000 + $i);
                    print $textline;
                    print $handle $textline;
                }
                $startIndex = -1;
            }
        }
    } else {
        foreach my $item (@_) {
            for ($i = 0; $i < 10000; $i++) {
                my $textline = getAddr($item * 10000 + $i);
                print $textline;
                print $handle $textline;
            }
        }
    }
}
sub getAddr {
    (my $phone) = @_;
    my $http = HTTP::Tiny->new();
    my $response = $http->get('http://wap.ip138.com/sim_search138.asp?mobile='.$phone);
    #print $response->{success}."\n";
    #print $response->{status}."\n";
    #print $response->{reason}."\n";
    #print $response->{content}."\n";
    my $content = $response->{content};
    my $keyword = '归属地：([^<]+)<';
    utf8::encode($keyword);
    my $res = $content =~ /$keyword/;
    my $type = '';
    my $textline = '';
    if ($res) {
        my $addr = $1;
        $keyword = '卡类型：([^<]+)<';
        utf8::encode($keyword);
        $res = $content =~ /$keyword/;
        if ($res) {
            $type = $1;
        }
        utf8::decode($addr);
        $textline = $phone."\t".$addr."\t".$type."\n";
    } else {
        $textline = $phone."\n";
    }
    $textline;
}

run(@phoneSegment);

