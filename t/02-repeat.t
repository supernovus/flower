#!/usr/bin/env perl6

BEGIN { @*INC.push: './lib' }

use Test;
use Flower;

plan 2;

my $xml = '<?xml version="1.0"?>';

my $template = '<test><item petal:repeat="item items" petal:attributes="alt item/alt" petal:content="item/content"/></test>';
my $flower = Flower.new(:template($template));
my @items = (
  { :alt<One>,   :content<First>  },
  { :alt<Two>,   :content<Second> },
  { :alt<Three>, :content<Third>  },
);

is $flower.parse(:items(@items)), $xml~'<test><item alt="One">First</item><item alt="Two">Second</item><item alt="Three">Third</item></test>', 'petal:repeat';

$template = '<test><div petal:repeat="item items" petal:omit-tag=""><tr><td petal:content="item/alt"/><td petal:content="item/content"/></tr></div></test>';
$flower = Flower.new(:template($template));
is $flower.parse(:items(@items)), $xml~'<test><tr><td>One</td><td>First</td></tr><tr><td>Two</td><td>Second</td></tr><tr><td>Three</td><td>Third</td></tr></test>', 'petal:repeat with nested elements and omit-tag';

