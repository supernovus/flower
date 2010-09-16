#!/usr/bin/env perl6

## A temporary testing file.
## This will be replaced by a proper test in t/ shortly.

use Flower;

my $template='<test><item name="booya" petal:define="oops my_test_var" petal:content="oops"/></test>';

my $parser = Flower.new(:template($template));

say $parser.parse(my_test_var => 'oh noes');

