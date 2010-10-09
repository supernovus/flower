module Flower::Utils::Text;

our sub all() {
  my %modifiers = {
    uppercase => &upper,
    upper     => &upper,
    'uc'      => &upper,
    lowercase => &lower,
    lower     => &lower,
    'lc'      => &lower,
    'ucfirst' => &uc_first,
    uc_first  => &uc_first,
    'substr'  => &sub_string,
    'printf'  => &print_formatted,
    'sprintf' => &print_formatted,
  };
  return %modifiers;
}

## Usage:  uc: varname
our sub upper ($parent, $query, *%opts) {
  my $result = $parent.query($query);
  return $parent.process-query($result.uc, |%opts);
}

## Usage:  lc: varname
our sub lower ($parent, $query, *%opts) {
  my $result = $parent.query($query);
  return $parent.process-query($result.lc, |%opts);
}

## Usage:  ucfirst: varname
our sub uc_first ($parent, $query, *%opts) {
  my $result = $parent.query($query);
  return $parent.process-query($result.ucfirst, |%opts);
}

## Usage:  substr: opts string/variable
## Opts: 1[,2][,3]  
##  where 1 is the offset to start at,
##  2 is the number of characters to keep,
##  and if 3 is true add an ellipsis (...) to the end.
## E.g.: <div tal:content="substr: 3,5 'theendoftheworld'"/>
## Returns: <div>endof</div>
our sub sub_string ($parent, $query, *%opts) {
  my ($subquery, $start, $chars, $ellipsis) = 
    $parent.get-args($query, 0, Nil, Nil);
  my $text = $parent.query($subquery);
  if defined $text {
    my $substr = $text.substr($start, $chars);
    if $ellipsis {
      $substr ~= '...';
    }
    return $parent.process-query($substr, |%opts);
  }
}

## Usage:  printf: format varname/path
## E.g.: <div tal:content="printf: '$%0.2f' '2.5'"/>
## Returns: <div>$2.50</div>
our sub print_formatted ($parent, $query, *%opts) {
  my ($format, $text) = $parent.get-args(:query, $query, Nil);
  if defined $text && defined $format {
    my $formatted = sprintf($format, $text);
    return $parent.process-query($formatted, |%opts);
  }
}

