#!/usr/bin/env perl6

## Based on the second repeat test, but using tal:block instead of omit-tag.

BEGIN { @*INC.unshift: './lib' }

use Test;
use Flower;

plan 1;

my $xml = '<?xml version="1.0"?>';

my @items = (
  { :alt<One>,   :content<First>  },
  { :alt<Two>,   :content<Second> },
  { :alt<Three>, :content<Third>  },
);

my $template = '<test><tal:block tal:repeat="item items"><tr><td tal:content="item/alt"/><td tal:content="item/content"/></tr></tal:block></test>';
my $flower = Flower.new(:template($template));
is $flower.parse(:items(@items)), $xml~'<test><tr><td>One</td><td>First</td></tr><tr><td>Two</td><td>Second</td></tr><tr><td>Three</td><td>Third</td></tr></test>', 'tal:block with a repeated item.';

