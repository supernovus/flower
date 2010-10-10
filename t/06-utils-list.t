#!/usr/bin/env perl6

BEGIN { @*INC.unshift: './lib' }

use Test;
use Flower;
use Exemel;

plan 7;

my $xml = '<?xml version="1.0"?>';

## test 1, group

my $template = '<table><tr tal:repeat="row group:items 2"><td tal:repeat="col row" tal:content="col"/></tr></table>';

my $flower = Flower.new(:template($template));

$flower.load-modifiers('List'); 

is $flower.parse(:items(['a'..'d'])), $xml~'<table><tr><td>a</td><td>b</td></tr><tr><td>c</td><td>d</td></tr></table>', 'group: modifier';

## test 2, sort

$template = '<fresh><i tal:repeat="item sort:items" tal:content="item"/></fresh>';
$flower.=another(:template($template));

my @items = 5,3,7,1,2;

is $flower.parse(:items(@items)), $xml~'<fresh><i>1</i><i>2</i><i>3</i><i>5</i><i>7</i></fresh>', 'sort: modifier';

## test 3, reverse

$template = '<reverse><i tal:repeat="item reverse:items" tal:content="item"/></reverse>';
$flower.=another(:template($template));

is $flower.parse(:items(@items)), $xml~'<reverse><i>2</i><i>1</i><i>7</i><i>3</i><i>5</i></reverse>', 'reverse: modifier';

## test 4, limit

$template = '<limit><i tal:repeat="item limit: items 2" tal:content="item"/></limit>';
$flower.=another(:template($template));

is $flower.parse(:items(@items)), $xml~'<limit><i>5</i><i>3</i></limit>', 'limit: modifier';

## test 5, limit using a variable

$template = '<limit><i tal:repeat="item limit: items ${limit}" tal:content="item"/></limit>';
$flower.=another(:template($template));

is $flower.parse(:items(@items), :limit(3)), $xml~'<limit><i>5</i><i>3</i><i>7</i></limit>', 'limit: modifier using a variable';

## test 6, shuffle

$template = '<shuffle><i tal:repeat="item shuffle: items" tal:content="item"/></shuffle>';
$flower.=another(:template($template));

my $doc = $flower.parse(:items(@items));
my $xdoc = Exemel::Element.parse($doc);

my @is = $xdoc.elements(:TAG<i>);
is @is.elems, 5, 'shuffle: proper number of elements returned';

## test 7, pick

$template = '<shuffle><i tal:repeat="item pick: items 3" tal:content="item"/></shuffle>';
$flower.=another(:template($template));

$doc = $flower.parse(:items(@items));
$xdoc = Exemel::Element.parse($doc);

@is = $xdoc.elements(:TAG<i>);
is @is.elems, 3, 'pick: proper number of elements returned';

