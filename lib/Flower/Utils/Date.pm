module Flower::Utils::Date;

use DateTime::Utils;

our sub all() {
  my %modifiers = {
    'date'     => &make_date,
    'time'     => &date_time,
    'strftime' => &strf_time,
    'rfc'      => &format_rfc,
    'now'      => &datetime_now,
  };
  return %modifiers;
}

## date: modifier, Creates a DateTime object with the given spec.
## Usage:  date: year [month] [day] [hour] [minute] [second] :tz(timezone)
## The named paramter 'tz' must be specified in the common ISO offset format,
## '-0800' would represent a timezone that is 8 hours behind UTC.
## '+0430' would represent a timezone that is 4 hours and 30 minutes ahead.

our sub make_date ($parent, $query, *%opts) {
  my ($year, $month, $day, $hour, $minute, $second, %params) =
    $parent.get-args(:query, :named, $query, 1, 1, 0, 0, 0);
  if defined $year {
    my $timezone = 0;
    if %params.exists('tz') && %params<tz> ~~ Str {
      $timezone = iso-offset(%params<tz>);
    }
    my $dt = DateTime.new(
        :year($year.Int), :month($month.Int), :day(+$day.Int), 
        :hour($hour.Int), :minute($minute.Int), :second($second.Int), 
        :timezone($timezone)
    );
    return $parent.process-query($dt, |%opts);
  }
}

## time: modifier, Creates a DateTime object based on an epoch integer/string.

our sub date_time ($parent, $query, *%opts) {
  my $epoch = $parent.query($query);
  my $dt = DateTime.new($epoch.Int);
  return $parent.process-query($dt, |%opts);
}

## strftime: modifier, formats a DateTime object.
## Usage:  strftime: format [date] [timezone]
## If date is not specified, it will be right now.
## For now with a specified timezone, use the now:
## modifier extension (see below).
## The date parameter can be a DateTime object, Date object
## or epoch integer/string.
## If you don't specify a timezone, then for Date objects
## or epoch integers, UTC will be used. DateTime objects will
## use their existing timezones.

our sub strf_time ($parent, $query, *%opts) {
  my ($format, $date, $timezone) = 
    $parent.get-args(:query, $query, DateTime.now(), Nil);
  if defined $format && defined $date {
    if defined $timezone {
      $timezone = iso-offset($timezone);
    }
    my $return;
    if $date ~~ DateTime {
      if defined $timezone {
        $date.=in-timezone($timezone);
      }
      $return = strftime($format, $date);
    }
    else {
      if !defined $timezone { $timezone = 0; }
      if $date ~~ Date {    
        $return = strftime($format, DateTime.new(:$date, :$timezone));
      }
      elsif $date ~~ Int {
        $return = strftime($format, DateTime.new($date, :$timezone));
      }
    }
  }
}

## rfc: special modifier extension for strftime.
## The only valid use for this, is in strftime: modifier queries.
## Don't use it on its own, as it assumes it's being parsed by strftime.
## Example:
## <div tal:content="strftime: rfc: {{date: 2010 10 10 :tz('-0800')}}"/>
## Will return <div>Sun, 10 Oct 2010 00:00:00 -0800</div>

our sub format_rfc ($parent, $query, *%opts) {
  return '%a, %d %b %Y %T %z';
}

## now: special modifier extension for strftime.
## Returns a datetime object representing 'right now'.
## It's in UTC by default, but that's okay, because the only
## real use for this is in strftime: where you may want to
## add a timezone, example:
## <div tal:content="strftime: rfc: now: '-0800'"/>
## Will return the current time in RFC format, in the -0800 timezone.

our sub datetime_now ($parent, $query, *%opts) {
  return DateTime.now();
}

