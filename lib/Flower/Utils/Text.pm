module Flower::Utils::Text;

our sub all() {
  my %modifiers = {
    uppercase => &upper,
    upper     => &upper,
    'uc'      => &upper,
    lowercase => &lower,
    lower     => &lower,
    'lc'      => &lower,
  };
  return %modifiers;
}

our sub upper ($parent, $query, *%opts) {
  my $result = $parent.query($query);
  return $parent.process-query($result.uc, |%opts);
}

our sub lower ($parent, $query, *%opts) {
  my $result = $parent.query($query);
  return $parent.process-query($result.lc, |%opts);
}

