module Flower::Utils::List;

our sub export() {
  my %modifiers = {
    group     => &list_group,
    'sort'    => &list_sort,
    'reverse' => &list_reverse,
    limit     => &list_limit,
    shuffle   => &list_pick,
    pick      => &list_pick,
  };
  return %modifiers;
}

our sub list_sort ($parent, $query, *%opts) {
  my $array = $parent.query($query);
  if $array ~~ Array {
    my @newarray = $array.sort;
    return @newarray;
  }
}

our sub list_group ($parent, $query, *%opts) {
  my ($array, $num) = $parent.get-args(:query({1=>1}), $query, 1);
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

our sub list_limit ($parent, $query, *%opts) {
  my ($array, $num) = $parent.get-args(:query({1=>1}), $query, 1);
  if $array ~~ Array {
    my $count = $num - 1;
    my @return = $array[0..$count];
    return @return;
  }
}

our sub list_pick ($parent, $query, *%opts) {
  my ($array, $num) = $parent.get-args(:query({1=>1}), $query, *);
  if $array ~~ Array {
    my @return = $array.pick($num);
    return @return;
  }
}

our sub list_reverse ($parent, $query, *%opts) {
  my $array = $parent.query($query);
  if $array ~~ Array {
    my @return = $array.reverse;
    return @return;
  }
}

