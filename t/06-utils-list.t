#!/usr/bin/env perl6

BEGIN { @*INC.unshift: './lib' }

use Test;
use Flower;

plan 2;

my $xml = '<?xml version="1.0"?>';

my $template = '<table><tr tal:repeat="row group:items 2"><td tal:repeat="col row" tal:content="col"/></tr></table>';

my $flower = Flower.new(:template($template));

$flower.load-modifiers('List'); 

is $flower.parse(:items(['a'..'d'])), $xml~'<table><tr><td>a</td><td>b</td></tr><tr><td>c</td><td>d</td></tr></table>', 'group: modifier';

$template = '<fresh><i tal:repeat="item sort:items" tal:content="item"/></fresh>';

$flower.=another(:template($template));

my @items = 5,3,7,1,2;

is $flower.parse(:items(@items)), $xml~'<fresh><i>1</i><i>2</i><i>3</i><i>5</i><i>7</i></fresh>', 'sort: modifier';

