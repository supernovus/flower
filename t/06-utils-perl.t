#!/usr/bin/env perl6

class FooBar {
  method amethod ($name) {
    return "Hello $name";
  }
}

BEGIN { @*INC.unshift: './lib' }

use Test;
use Flower;

plan 5;

my $xml = '<?xml version="1.0"?>';

## test 1

my $template = '<test><query tal:replace="perl:ahash<anobj>.amethod(\'world\')"/></test>';
my $flower = Flower.new(:template($template));

my %ahash = {
  'anobj' => FooBar.new,
  'anum'  => 2.5,
  'abad'  => '5 * 5',
}

$flower.load-modifiers('Perl');

is $flower.parse(ahash => %ahash), $xml~'<test>Hello world</test>', 'perl: modifier';

## test 2, oh God this is dangerous.

$template = '<test tal:content="perlx: ahash/anum.Num * 2"/>';
$flower.=another(:template($template));
$flower.add-modifier('perlx', &Flower::Utils::Perl::perl_lookup);
is $flower.parse(ahash => %ahash), $xml~'<test>5</test>', 'perl_lookup modifier (dangerous)';

## test 3, please, don't enable this, it's a security hole waiting to happen.

$template = '<test tal:content="perlxx: pi.fmt(\'%0.4f\')"/>';
$flower.=another(:template($template));
$flower.add-modifier('perlxx', &Flower::Utils::Perl::perl_execute);
is $flower.parse(), $xml~'<test>3.1416</test>', 'perl_execute modifier (really dangerous)';

## test 4, let's try using an illegal word.

$template = '<test tal:content="perl: ahash<abad>.eval"/>';
$flower.=another(:template($template));
is $flower.parse(ahash => %ahash), $xml~'<test>5 * 5</test>', 'perl: filtered out an attempt to eval a string';

## test 5, another illegal one.

$template = '<test tal:content="perlxx: run \'ls\'"/>';
$flower.=another(:template($template));
is $flower.parse(), $xml~'<test/>', 'filtered out an attempt to use run().';

