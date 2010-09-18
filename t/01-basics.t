#!/usr/bin/env perl6

BEGIN { @*INC.push: './lib' }

use Test;
use Flower;

plan 5;

my $xml = '<?xml version="1.0"?>';

my $template = '<test><item petal:define="test my_test_var" petal:content="test"/></test>';
my $flower = Flower.new(:template($template));
is $flower.parse(my_test_var => 'Hello World'), $xml~'<test><item>Hello World</item></test>', 'petal:define and petal:content';

$template = '<test><replaced petal:replace="hello">This will be replaced</replaced></test>';
$flower = Flower.new(:template($template));
is $flower.parse(hello => 'Hello World'), $xml~'<test>Hello World</test>', 'petal:replace';

$template = '<test><true petal:condition="hello">This is true</true><false petal:condition="notreal">This is false</false><right petal:condition="true:hello"/><wrong petal:condition="false:hello"/></test>';
$flower = Flower.new(:template($template));
is $flower.parse(hello => 'Hello World'), $xml~'<test><true>This is true</true><right/></test>', 'petal:condition';

$template = '<test><div petal:omit-tag="">Good <b petal:omit-tag="hello">Day</b> Mate</div></test>';
#$template = '<test><div petal:omit-tag="string:1">Good Day Mate</div></test>';
$flower = Flower.new(:template($template));
is $flower.parse(hello => 'hello world'), $xml~'<test>Good Day Mate</test>', 'petal:omit-tag';

$template = '<test><attrib petal:attributes="hello hello; cya goodbye"/></test>';
$flower = Flower.new(:template($template));
my $matched = False;
my $output = $flower.parse(hello => 'Hello World', goodbye => 'Goodbye Universe');
if $output eq $xml~'<test><attrib hello="Hello World" cya="Goodbye Universe"/></test>' { $matched = True; }
elsif $output eq $xml~'<test><attrib cya="Goodbye Universe" hello="Hello World"/></test>' { $matched = True; }
ok $matched, 'petal:attributes';

