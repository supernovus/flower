module Flower::DefaultModifiers;

our sub export() {
  my %modifiers = {
    str    => &string,
    string => &string,
    is     => &true,
    true   => &true,
    false  => &false,
    'not'  => &false,
  };
  return %modifiers;
}

our sub true ($parent, $query, *%opts) {
  my $result = $parent.query($query, :bool);
  return ?$result;
}

our sub false ($parent, $query, *%opts) {
  my $result = $parent.query($query, :bool);
  if $result { return False; }
  else { return True; }
}

our sub string ($parent, $query, *%opts) {
  my $string = $parent.parse-string($query);
  return $parent.process-query($string, |%opts);
}

