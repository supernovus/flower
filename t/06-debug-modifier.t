#!/usr/bin/env perl6

BEGIN { @*INC.unshift: './lib' }

use Test;
use Flower;
use Flower::Utils::Debug;

plan 1;

my $xml = '<?xml version="1.0"?>';

my $template = '<test><dump tal:content="dump:object" tal:attributes="type what:object"/></test>';
my $flower = Flower.new(:template($template));

my %ahash = {
  'anarray' => [ 'one', 'two', 'three' ],
}

$flower.add-modifiers(Flower::Utils::Debug::all());

is $flower.parse(object => %ahash), $xml~'<test><dump type="Hash">{"anarray" => ["one", "two", "three"]}</dump></test>', 'dump: and what: modifiers';

