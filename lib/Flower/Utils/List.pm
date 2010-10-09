module Flower::Utils::List;

our sub all() {
  my %modifiers = {
    group  => &array_group,
    'sort' => &array_sort,
  };
  return %modifiers;
}

our sub array_sort ($parent, $query, *%opts) {
  my $array = $parent.query($query);
  if $array ~~ Array {
    my @newarray = $array.sort;
    return @newarray;
  }
}

our sub array_group ($parent, $query, *%opts) {
  my ($subquery, $num) = $parent.get-args($query, 1);
  my $array = $parent.query($subquery);
  if $array ~~ Array {
    my @nest = ([]);
    my $level = 0;
    loop (my $i=0; $i < $array.elems; $i++) {
      if $level > @nest.end {
        @nest.push: [];
      }
      @nest[$level].push: $array[$i];
      if ($i+1) % $num == 0 {
        $level++;
      }
    }
    return @nest;
  }
}

