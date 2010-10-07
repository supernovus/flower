#!/usr/bin/env perl6

## TODO: Separate out the string: parsing from the uc: parsing.
## Add a separate set of tests for Flower::Utils::Text, and one
## for all modifiers in the DefaultModifiers set.

BEGIN { @*INC.unshift: './lib' }

use Test;
use Flower;
use Flower::Utils::Text;

plan 1;

my $xml = '<?xml version="1.0"?>';

my $template = '<test><upper tal:content="uc:string:A test of ${name}, in uppercase."/></test>';
my $flower = Flower.new(:template($template));

$flower.add-modifiers(Flower::Utils::Text::all());

is $flower.parse(name => 'Flower'), $xml~'<test><upper>A TEST OF FLOWER, IN UPPERCASE.</upper></test>', 'string: and custom :uc modifiers';

