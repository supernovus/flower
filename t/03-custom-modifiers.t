#!/usr/bin/env perl6

## TODO: Separate out the string: parsing from the uc: parsing.
## Add a separate set of tests for Flower::Utils::Text, and one
## for all modifiers in the DefaultModifiers set.

BEGIN { 
  @*INC.unshift: './lib';    ## Standard lib.
  @*INC.unshift: './t/lib';  ## Test libraries.
}

use Test;
use Flower;
use Example::Modifiers;

plan 1;

my $xml = '<?xml version="1.0"?>';

my $template = '<test><woah tal:replace="woah:crazy"/></test>';
my $flower = Flower.new(:template($template));

$flower.add-modifiers(Example::Modifiers::all());

is $flower.parse(crazy => 'hello world'), $xml~'<test>Woah, hello world, that\'s awesome!</test>', 'custom modifiers';

