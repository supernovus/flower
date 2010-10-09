#!/usr/bin/env perl6

BEGIN { @*INC.unshift: './lib' }

use Test;
use Flower;

plan 6;

my $xml = '<?xml version="1.0"?>';

## test 1

my $template = '<test><upper tal:content="uc:string:A test of ${name}, in uppercase."/></test>';
my $flower = Flower.new(:template($template));

$flower.load-modifiers('Text');

is $flower.parse(name => 'Flower'), $xml~'<test><upper>A TEST OF FLOWER, IN UPPERCASE.</upper></test>', 'uc: modifier';

## test 2

$template = '<test><lower tal:content="lc:string:I AM NOT YELLING"/></test>';

$flower.=another(:template($template));

is $flower.parse(), $xml~'<test><lower>i am not yelling</lower></test>', 'lc: modifier';

## test 3

$template = '<test><ucfirst tal:replace="ucfirst:string:bob"/></test>';

$flower.=another(:template($template));

is $flower.parse(), $xml~'<test>Bob</test>', 'ucfirst: modifier';

## test 4

$template = '<test><substr tal:replace="substr:3,5 \'theendoftheworld\'"/></test>';

$flower.=another(:template($template));

is $flower.parse(), $xml~'<test>endof</test>', 'substr: modifier';

## test 5

$template = '<test><substr tal:replace="substr:3,5,1 \'theendoftheworld\'"/></test>';

$flower.=another(:template($template));

is $flower.parse(), $xml~'<test>endof...</test>', 'substr: modifier with ellipsis';

## test 6

$template = '<test><printf tal:replace="printf: \'$%0.2f\' \'2.5\'"/></test>';

$flower.=another(:template($template));

is $flower.parse(), $xml~'<test>$2.50</test>', 'printf: modifier';

