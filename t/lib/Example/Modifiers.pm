module Example::Modifiers;

our sub all() {
  my %modifiers = {
    woah => &woahize,
  };
  return %modifiers;
}

our sub woahize ($parent, $query, *%opts) {
  my $result = $parent.query($query);
  my $woah = "Woah, $result, that's awesome!";
  return $parent.process-query($woah, |%opts);
}

