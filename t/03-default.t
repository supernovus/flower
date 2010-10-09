#!/usr/bin/env perl6

BEGIN { @*INC.unshift: './lib' }

use Test;
use Flower;

plan 2;

my $xml = '<?xml version="1.0"?>';

## test 1

my $template = '<test><i tal:content="default">The default text</i></test>';
my $flower = Flower.new(:template($template));

is $flower.parse(), $xml~'<test><i>The default text</i></test>', 'tal:content with default';

## test 2

$template = '<test><i tal:replace="default">The default text</i></test>';
$flower.=another(:template($template));

is $flower.parse(), $xml~'<test>The default text</test>', 'tal:replace with default';


