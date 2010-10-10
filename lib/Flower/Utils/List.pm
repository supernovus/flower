module Flower::Utils::List;

our sub all() {
  my %modifiers = {
    group     => &array_group,
    'sort'    => &array_sort,
    'reverse' => &array_reverse,
    limit     => &array_limit,
    shuffle   => &array_pick,
    pick      => &array_pick,
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

our sub array_limit ($parent, $query, %*opts) {
  my ($subquery, $num) = $parent.get-args($query, 1);
  my $array = $parent.query($subquery);
  if $array ~~ Array {
    my $count = $num - 1;
    return $array[0..$count];
  }
}

our sub array_pick ($parent, $query, %*opts) {
  my ($subquery, $num) = $parent.get-args($query, *);
  my $array = $parent.query($subquery);
  if $array ~~ Array {
    return $array.pick($num);
  }
}

our sub array_reverse ($parent, $query, %*opts) {
  my $array = $parent.query($query);
  if $array ~~ Array {
    return $array.reverse;
  }
}

