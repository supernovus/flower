module Flower::Utils::Debug;

our sub export() {
  my %modifiers = {
    dump => &debug_dump,
    what => &debug_what,
  };
  return %modifiers;
}

our sub debug_dump($parent, $query, *%opts) {
  my $result = $parent.query($query, :noescape);
  %opts.delete('noescape');
  return $parent.process-query($result.perl, :noescape, |%opts);
}

our sub debug_what($parent, $query, *%opts) {
  my $result = $parent.query($query, :noescape);
  %opts.delete('noescape');
  return $parent.process-query($result.WHAT.perl, :noescape, |%opts);
}

