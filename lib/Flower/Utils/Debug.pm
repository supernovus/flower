module Flower::Utils::Perl;

## Like it's cousins 'python:' and 'php:', the 'perl:' modifier allows
## you to query the data using the native Perl 6 format instead of the
## path syntax. Example: <eg tal:replace="perl:my-hash<key>.method('param')" />
## The 'my-hash' in the example must be a valid key in the Flower data.

our sub all() {
  my %modifiers = {
    dump => &dump_perl,
    what => &what_perl,
  };
  return %modifiers;
}

our sub dump_perl($parent, $query, *%opts) {
  my $result = $parent.query($query, :noescape);
  %opts.delete('noescape');
  return $parent.process-query($result.perl, :noescape, |%opts);
}

our sub what_perl($parent, $query, *%opts) {
  my $result = $parent.query($query, :noescape);
  %opts.delete('noescape');
  return $parent.process-query($result.WHAT.perl, :noescape, |%opts);
}

