#!/usr/bin/env perl6

BEGIN { @*INC.unshift: './lib' }

use Test;
use Flower;

plan 8;

my $xml = '<?xml version="1.0"?>';

my $template = '<test><item tal:define="test my_test_var" tal:content="test"/></test>';
my $flower = Flower.new(:template($template));
is $flower.parse(my_test_var => 'Hello World'), $xml~'<test><item>Hello World</item></test>', 'tal:define and tal:content';

$template = '<test><item tal:define="test1 my_test_var1; test2 my_test_var2" tal:content="string:${test1} = ${test2}"/></test>';
$flower.=another(:template($template));
is $flower.parse(my_test_var1 => 'Hello', my_test_var2 => 'World'), $xml~'<test><item>Hello = World</item></test>', 'tal:define with multiple definitions.';

$template = '<test><replaced tal:replace="hello">This will be replaced</replaced></test>';
$flower.=another(:template($template));
is $flower.parse(hello => 'Hello World'), $xml~'<test>Hello World</test>', 'tal:replace';

$template = '<test><true tal:condition="hello">This is true</true><false tal:condition="notreal">This is false</false><right tal:condition="true:hello"/><wrong tal:condition="false:hello"/></test>';
$flower.=another(:template($template));
is $flower.parse(hello => 'Hello World'), $xml~'<test><true>This is true</true><right/></test>', 'tal:condition';

$template = '<test><div tal:omit-tag="">Good <b tal:omit-tag="hello">Day</b> Mate</div></test>';
#$template = '<test><div tal:omit-tag="string:1">Good Day Mate</div></test>';
$flower.=another(:template($template));
is $flower.parse(hello => 'hello world'), $xml~'<test>Good Day Mate</test>', 'tal:omit-tag';

$template = '<test><attrib tal:attributes="hello hello; cya goodbye"/></test>';
$flower.=another(:template($template));
my $matched = False;
my $output = $flower.parse(hello => 'Hello World', goodbye => 'Goodbye Universe');
if $output eq $xml~'<test><attrib hello="Hello World" cya="Goodbye Universe"/></test>' { $matched = True; }
elsif $output eq $xml~'<test><attrib cya="Goodbye Universe" hello="Hello World"/></test>' { $matched = True; }
ok $matched, 'tal:attributes';

$template = '<test><hello/><goodbye tal:replace=""/></test>';
$flower.=another(:template($template));
is $flower.parse(), $xml~'<test><hello/></test>', 'tal:replace when empty.';

$template = '<test xmlns:petal="http://xml.zope.org/namespaces/tal"><div petal:replace="test"/></test>';
$flower.=another(:template($template));
is $flower.parse(test=>'Hello World'), $xml~'<test xmlns:petal="http://xml.zope.org/namespaces/tal">Hello World</test>', 'tal:replace with custom namespace.';

