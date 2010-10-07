#!/usr/bin/env perl6

BEGIN { @*INC.unshift: './lib' }

use Test;
use Flower;

plan 2;

my $xml = '<?xml version="1.0"?>';

my $template = '<test><item tal:repeat="item items" tal:attributes="alt item/alt" tal:content="item/content"/></test>';
my $flower = Flower.new(:template($template));
my @items = (
  { :alt<One>,   :content<First>  },
  { :alt<Two>,   :content<Second> },
  { :alt<Three>, :content<Third>  },
);

is $flower.parse(:items(@items)), $xml~'<test><item alt="One">First</item><item alt="Two">Second</item><item alt="Three">Third</item></test>', 'tal:repeat';

$template = '<test><div tal:repeat="item items" tal:omit-tag=""><tr><td tal:content="item/alt"/><td tal:content="item/content"/></tr></div></test>';
$flower = Flower.new(:template($template));
is $flower.parse(:items(@items)), $xml~'<test><tr><td>One</td><td>First</td></tr><tr><td>Two</td><td>Second</td></tr><tr><td>Three</td><td>Third</td></tr></test>', 'tal:repeat with nested elements and omit-tag';

