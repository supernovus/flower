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

our sub upper ($parent, $query) {
  my $result = $parent.query($query);
  return $result.uc;
}

our sub lower ($parent, $query) {
  my $result = $parent.query($query);
  return $result.lc;
}
