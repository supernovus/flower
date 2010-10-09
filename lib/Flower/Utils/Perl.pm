module Flower::Utils::Perl;

## Similar to it's cousins 'python:' and 'php:', the 'perl:' modifier allows
## you to query the data using the native Perl 6 format instead of the
## path syntax. Example: <eg tal:replace="perl:my-hash<key>.method('param')" />
## The 'my-hash' in the example must be a valid key in the Flower data.

## This is a dangerous library, know what you are doing before you enable this.
## There's only so much that can be filtered out, so be careful.

our sub all() {
  my %modifiers = {
    perl  => &perl_query,
  };
  return %modifiers;
}

my sub clean_perl ($perl is rw) {
  my token callsign { [ '(' | \s+ ] }
  my regex badwords { 
    | \.IO.* 
    | 'run' <&callsign> .* 
    | 'unlink' <&callsign> .* 
    | \.?eval .*
  }
  $perl.=subst(/<&badwords>/, '', :g); ## Murder bad things.
}

## perl: the only modifier included by default, when loading this plugin.
our sub perl_query ($parent, $query, *%opts) {
  my token keyname { <-['<'|'('|'.'|'{'|'['|'«']>+ }
  my $perl = $query.subst(/^(<&keyname>)/, -> $/ { '$parent.data<'~$0~'>' });
  clean_perl($perl);
  my $result = eval($perl);
  return $parent.process-query($result, |%opts);
}

## perlx: Look up a value, then run methods on the string it returns.
##        Not exported by default, you must request this modifier.
our sub perl_lookup ($parent, $query, *%opts) {
  my ($subquery, $perl) = $query.split(/\./, 2);
  clean_perl($perl);
  my $lookup = $parent.query($subquery);
  my $result = eval("'$lookup'."~$perl);
  return $parent.process-query($result, |%opts);
}

## perlxx: Execute arbitrary Perl 6 code, and return the output.
##         Not exported by default, you must request this modifier.
our sub perl_execute ($parent, $query, *%opts) {
  my $perl = $query;
  clean_perl($perl);
  my $result = eval($perl);
  if defined $result {
    return $parent.process-query($result, |%opts);
  }
  else {
    return;
  }
}

