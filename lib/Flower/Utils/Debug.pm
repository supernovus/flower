module Flower::Utils::Debug;

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

