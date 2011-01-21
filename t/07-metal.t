#!/usr/bin/env perl6

BEGIN { @*INC.unshift: './blib', './lib' }

use Test;
use Flower;

plan 3;

my $xml = '<?xml version="1.0"?>';

## test 1, basic define and use.

my $template = '<test><zool metal:define-macro="hello">Hello World</zool><zed metal:use-macro="hello">Goodbye Universe</zed></test>';
my $flower = Flower.new(:template($template));
is $flower.parse(), $xml~'<test><zool>Hello World</zool><zool>Hello World</zool></test>', 'metal:define-macro and metal:use-macro';

## test 2, using from an external file.

$template = '<test><zed metal:use-macro="./t/metal/common.xml#hello">Say Hi</zed></test>';
$flower.=another(:template($template));
is $flower.parse(), $xml~'<test><zool>Hello, World.</zool></test>', 'metal:use-macro with external reference.';

## test 3, slots.

$template = '<test><zed metal:use-macro="./t/metal/common.xml#slotty">A slotty test, <orb metal:fill-slot="booya">Yippie Kai Yay!</orb>.</zed></test>';
$flower.=another(:template($template));
is $flower.parse(), $xml~'<test><zarf>It is known, <orb>Yippie Kai Yay!</orb>, what do you think?</zarf></test>', 'metal:define-slot and metal:fill-slot';

