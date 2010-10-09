module Flower::Utils::Date;

use DateTime::Utils;

our sub all() {
  my %modifiers = {
    date => &make_date,
#    time => &date_time,
#    strftime => &strf_time,
#    rfc => &timestamp_rfc,
  };
  return %modifiers;
}

our sub date($parent, $query, *%opts) {
  my ($year, $month, $day, $hour, $minute, $second) =
    $parent.get-args(:query, $query, Nil xx 5);
  my $dt = DateTime.new($year, $month, $day, $hour, $minute, $second);
  return $parent.process-query($dt, |%opts);
}

