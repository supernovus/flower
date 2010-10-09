#!/usr/bin/env perl6

BEGIN { @*INC.unshift: './lib' }

use Test;
use Flower;

plan 10;

sub attrmake (*@opts) { @opts.join(' ') | @opts.reverse.join(' ') }

my $xml = '<?xml version="1.0"?>';

## test 1

my $template = '<test><item tal:define="test my_test_var" tal:content="test"/></test>';
my $flower = Flower.new(:template($template));
is $flower.parse(my_test_var => 'Hello World'), $xml~'<test><item>Hello World</item></test>', 'tal:define and tal:content';

## test 2

$template = '<test><item tal:define="test1 my_test_var1; test2 my_test_var2" tal:content="string:${test1} = ${test2}"/></test>';
$flower.=another(:template($template));
is $flower.parse(my_test_var1 => 'Hello', my_test_var2 => 'World'), $xml~'<test><item>Hello = World</item></test>', 'tal:define with multiple definitions.';

## test 3

$template = '<test><replaced tal:replace="hello">This will be replaced</replaced></test>';
$flower.=another(:template($template));
is $flower.parse(hello => 'Hello World'), $xml~'<test>Hello World</test>', 'tal:replace';

## test 4

$template = '<test><true tal:condition="hello">This is true</true><false tal:condition="notreal">This is false</false><right tal:condition="true:hello"/><wrong tal:condition="false:hello"/></test>';
$flower.=another(:template($template));
is $flower.parse(hello => 'Hello World'), $xml~'<test><true>This is true</true><right/></test>', 'tal:condition';

## test 5

$template = '<test><div tal:omit-tag="">Good <b tal:omit-tag="hello">Day</b> Mate</div></test>';
#$template = '<test><div tal:omit-tag="string:1">Good Day Mate</div></test>';
$flower.=another(:template($template));
is $flower.parse(hello => 'hello world'), $xml~'<test>Good Day Mate</test>', 'tal:omit-tag';

## test 6

$template = '<test><attrib tal:attributes="hello hello; cya goodbye"/></test>';
$flower.=another(:template($template));
my $attrpos = attrmake 'hello="Hello World"', 'cya="Goodbye Universe"';
is $flower.parse(hello => 'Hello World', goodbye => 'Goodbye Universe'),
   $xml~'<test><attrib '~$attrpos~'/></test>', 'tal:attributes';

## test 7

$template = '<test><hello/><goodbye tal:replace=""/></test>';
$flower.=another(:template($template));
is $flower.parse(), $xml~'<test><hello/></test>', 'tal:replace when empty.';

## test 8

$template = '<test xmlns:petal="http://xml.zope.org/namespaces/tal"><div petal:replace="test"/></test>';
$flower.=another(:template($template));
is $flower.parse(test=>'Hello World'), $xml~'<test xmlns:petal="http://xml.zope.org/namespaces/tal">Hello World</test>', 'tal:replace with custom namespace.';

## test 9

$template = '<test tal:attributes="id id">Test document</test>';
$flower.=another(:template($template));
is $flower.parse(id=>'first'), $xml~'<test id="first">Test document</test>', 'attributes on root document';

## test 10

my @options = (
  { value => 'a', label => 'Option 1' },
  { value => 'b', label => 'Option 2', selected => 'selected' },
  { value => 'c', label => 'Option 3' },
);

$template = '<select><option tal:repeat="option options" tal:attributes="value option/value; selected option/selected" tal:content="option/label"/></select>';

$flower.=another(:template($template));

$attrpos = attrmake 'value="b"', 'selected="selected"';

is $flower.parse(options => @options), $xml~'<select><option value="a">Option 1</option><option '~$attrpos~'>Option 2</option><option value="c">Option 3</option></select>', 'attributes with undefined value';

