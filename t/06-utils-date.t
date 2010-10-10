#!/usr/bin/env perl6

BEGIN { @*INC.unshift: './lib' }

use Test;
use Flower;

plan 6;

my $xml = '<?xml version="1.0"?>';

my %date = {
  'date'     => Date.new(2010,10,9),
  'datetime' => DateTime.new(
    :year(2010), :month(10), :day(11), 
    :hour(13), :minute(17), :second(14),
    :timezone('16200') # +0430
  ),
};

## test 1

my $template = "<date tal:content=\"date: '2010' '10' '10'\"/>";
my $flower = Flower.new(:template($template));

$flower.load-modifiers('Date');

is $flower.parse(), $xml~'<date>2010-10-10T00:00:00Z</date>', 'date: modifier';

## test 2

$template = '<date tal:content="time: \'1286666133\'"/>';
$flower.=another(:template($template));

is $flower.parse(), $xml~'<date>2010-10-09T23:15:33Z</date>', 'time: modifier';

## test 3

$template = '<date tal:content="strftime: \'%Y_%m_%d-%T\' date/datetime"/>';
$flower.=another(:template($template));

is $flower.parse(:date(%date)), $xml~'<date>2010_10_11-13:17:14</date>', 'strftime: modifier on a datetime object';

## test 4

$template = '<date tal:content="strftime: \'%b %d, %Y\' date/date"/>';
$flower.=another(:template($template));

is $flower.parse(:date(%date)), $xml~'<date>Oct 09, 2010</date>', 'strftime: modifier on a date object';

## test 5

$template = "<date tal:content=\"strftime: rfc: \{\{date: '2010' '10' '10' :tz('-0800')}}\"/>";
$flower.=another(:template($template));

is $flower.parse(), $xml~'<date>Sun, 10 Oct 2010 00:00:00 -0800</date>', 'strftime: with rfc: modifier';

## test 6

$template = '<date tal:content="strftime: \'%Y-%m-%d\' now:"/>';
my $now = Date.today();
$flower.=another(:template($template));

is $flower.parse(), $xml~'<date>'~$now~'</date>', 'strftime: with now: modifier';

