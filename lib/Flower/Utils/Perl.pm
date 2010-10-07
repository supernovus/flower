module Flower::Utils::Perl;

## Like it's cousins 'python:' and 'php:', the 'perl:' modifier allows
## you to query the data using the native Perl 6 format instead of the
## path syntax. Example: <eg tal:replace="perl:my-hash<key>.method('param')" />
## The 'my-hash' in the example must be a valid key in the Flower data.

our sub all() {
  my %modifiers = {
    perl => &perl_query,
  };
  return %modifiers;
}

our sub perl_query ($parent, $query, *%opts) {
  my token keyname { <-['<'|'('|'.'|'{'|'['|'«']>+ };
  my $perl = $query.subst(/^(<&keyname>)/, -> $/ { '$parent.data<'~$0~'>' });
  $perl.=subst('.eval','.chomp', :g); ## Kill any attempts to eval.
  my $result = eval($perl);
  return $parent.process-query($result, |%opts);
}

