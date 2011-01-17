class Flower;

use Exemel;
use Flower::DefaultModifiers;

has $.template;

has $!tal   is rw = 'tal';
has $!metal is rw = 'metal';
has $!i18n  is rw = 'i18n';

has $!tal-ns   = 'http://xml.zope.org/namespaces/tal';
has $!metal-ns = 'http://xml.zope.org/namespaces/metal';
has $!i18n-ns  = 'http://xml.zope.org/namespaces/i18n';

## a restricted set of tags for the root element.
has @!root-tal-tags = 'define', 'attributes', 'content';

## the normal set of TAL tags for every other element.
has @!tal-tags = 'define', 'condition', 'repeat', 'attributes', 'content', 'replace', 'omit-tag';

## the tags for METAL processing, not yet implemented.
has @!metal-tags = 'define-macro', 'use-macro', 'define-slot', 'fill-slot';

## Override find with a subroutine that can find templates based off
## of whatever your needs are (multiple roots, extensions, etc.)
has $!find;

## Modifiers, keys are strings, values are subroutines.
has %!modifiers;

## Data, is used to store the replacement data. Is available for modifiers.
has %.data is rw;

## Default stores the elements in order of parsing.
## Used to get the 'default' value, and other such stuff.
has @.elements;

## Internal class, used for the 'repeat' object.
class Flower::Repeat {
  has $.index;
  has $.length;

  method number { $.index + 1           }
  method start  { $.index == 0          }
  method end    { $.index == $.length-1 }
  method odd    { $.number % 2 != 0      }
  method even   { $.number % 2 == 0      }

  method inner  { $.index != 0 && $.index != $.length-1 }

  ## Flower exclusive methods below here, make lists and tables easier.
  method every  ($num) { $.number % $num == 0 }
  method skip   ($num) { $.number % $num != 0 }
  method lt     ($num) { $.number < $num      }
  method gt     ($num) { $.number > $num      }
  method eq     ($num) { $.number == $num     }
  method ne     ($num) { $.number != $num     }

  ## Versions of every and skip that also match on start.
  method repeat-every ($num) { $.start || $.every($num) }
  method repeat-skip  ($num) { $.start || $.every($num) }
}

method new (:$find is copy, :$file, :$template is copy) {
  if ( ! $file && ! $template ) { die "a file or template must be specified."; }
  if ! $find {
    $find = sub ($file) {
      if $file.IO ~~ :f { return $file; }
    }
  }
  if $file {
    my $filename;
    if ($file.IO ~~ :f) { $filename = $file; }
    else { $filename = $find($file); }
    $template = Exemel::Document.parse(slurp($filename));
  }
  else {
    if $template ~~ Exemel::Document {
      1; # we don't need to do anything.
    }
    elsif $template ~~ Exemel::Element {
      $template = Exemel::Document.new(:root($template));
    }
    elsif $template ~~ Str {
      $template = Exemel::Document.parse($template);
    }
    else {
      die "invalid template type passed.";
    }
  }
  my %modifiers = Flower::DefaultModifiers::export();
  self.bless(*, :$template, :$find, :%modifiers);
}

## A way to spawn another Flower using the same find and modifiers.
method another (:$file, :$template) {
  if ( ! $file && ! $template ) { die "a file or template must be specified."; }
  my $new = Flower.new(:$file, :$template, :find($!find));
  $new.add-modifiers(%!modifiers);
  return $new;
}

method !xml-ns ($ns) {
  return $ns.subst(/^xmlns\:/, '');
}

## Note: Once you have parsed, the template will forever be changed.
## You can't parse twice, so don't fark it up!
## You can access the template Exemel::Document object by using the
## $flower.template attribute.
method parse (*%data) {
  ## First we need to set the data.
  %.data = %data;

  ## Next, let's see if the namespaces have been renamed.
  for $.template.root.attribs.kv -> $key, $val {
    if $val eq $!tal-ns {
      $!tal = self!xml-ns($key);
    }
    elsif $val eq $!metal-ns {
      $!metal = self!xml-ns($key);
    }
    elsif $val eq $!i18n-ns {
      $!i18n = self!xml-ns($key);
    }
  }

  ## Okay, now let's parse the elements.
  self!parse-element($.template.root, @!root-tal-tags);
  return ~$.template;
}

## parse-elements, currently only does tal items.
## metal will be added in the next major release.
## i18n will be added at some point in the future.
## also TODO: implement 'on-error'.
method !parse-elements ($xml is rw) {
  ## Due to the strange nature of some rules, we're not using the
  ## 'elements' helper, nor using a nice 'for' loop. Instead we're doing this
  ## by hand. Don't worry, it'll all make sense.
#  if ! $xml.nodes { return; }
  loop (my $i=0; True; $i++) {
    if $i == $xml.nodes.elems { last; }
    my $element = $xml.nodes[$i];
    if $element !~~ Exemel::Element { next; } # skip non-elements.
    @.elements.unshift: $element; ## Stuff the newest element into place.
    self!parse-element($element);
    @.elements.shift; ## and remove it again.
    ## Now we clean up removed elements, and insert replacements.
    if ! defined $element {
      $xml.nodes.splice($i--, 1);
    }
    elsif $element ~~ Array {
      $xml.nodes.splice($i--, 1, |@($element));
    }
    else {
      $xml.nodes[$i] = $element; # Ensure the node is updated.
    }
  }
}

method !parse-element($element is rw, @tal-tags = @!tal-tags) {
  for @tal-tags -> $tal {
    my $tag = $!tal~':'~$tal;
    self!parse-tag($element, $tag, $tal);
    if $element !~~ Exemel::Element { last; } # skip if we changed type.
  }
## tal:block borrowed from PHPTAL.
  if ($element ~~ Exemel::Element && $element.name eq $!tal~':block') {
    $element = $element.nodes;
  }
## Haven't figured out METAL stuff entirely yet.
# for @metal -> $metal {
#   my $tag = $!metal~':'~$metal;
#   self!parse-tag($element, $tag, $metal);
# }
## Now let's parse any child elements.
  if $element ~~ Exemel::Element {
    self!parse-elements($element);
  }
}

method !parse-tag ($element is rw, $tag, $ns) {
  my $method = 'parse-'~$ns;
  if $element.attribs.exists($tag) {
    self!"$method"($element, $tag);
  }
}

method !parse-define ($xml is rw, $tag) {
  my @statements = $xml.attribs{$tag}.split(/\;\s+/);
  for @statements -> $statement {
    my ($attrib, $query) = $statement.split(/\s+/, 2);
    my $val = self.query($query);
    if defined $val { %.data{$attrib} = $val; }
  }
  $xml.unset($tag);
}

method !parse-condition ($xml is rw, $tag) {
  if self.query($xml.attribs{$tag}, :bool) {
    $xml.unset($tag);
  } else {
    $xml = Nil;
  }
}

method !parse-content ($xml is rw, $tag) {
  my $node = self.query($xml.attribs{$tag}, :forcexml);
  if defined $node {
    if $node === $xml.nodes {} # special case for 'default'.
    else {
      $xml.nodes.splice;
      $xml.nodes.push: $node;
    }
  }
  $xml.unset: $tag;
}

method !parse-replace ($xml is rw, $tag) {
  my $text = $xml.attribs{$tag};
  if defined $text {
    $xml = self.query($text, :forcexml); 
  }
  else {
    $xml = Nil;
  }
}

method !parse-attributes ($xml is rw, $tag) {
  my @statements = $xml.attribs{$tag}.split(/\;\s+/);
  for @statements -> $statement {
    my ($attrib, $query) = $statement.split(/\s+/, 2);
    my $val = self.query($query, :noxml);
    if defined $val {
      $xml.set($attrib, $val);
    }
  }
  $xml.unset: $tag;
}

method !parse-repeat ($xml is rw, $tag) { 
  my ($attrib, $query) = $xml.attribs{$tag}.split(/\s+/, 2);
  my $array = self.query($query);
  if (defined $array && $array ~~ Array) {
    if (! %.data.exists('repeat') || %.data<repeat> !~~ Hash) {
      %.data<repeat> = {}; # Initialize the repeat hash.
    }
    $xml.unset($tag);
    my @elements;
    my $count = 0;
    for @($array) -> $item {
      my $newxml = $xml.deep-clone;
      %.data{$attrib} = $item;
      my $repeat = Flower::Repeat.new(:index($count), :length($array.elems));
      %.data<repeat>{$attrib} = $repeat;
      my $wrapper = Exemel::Element.new(:nodes(($newxml)));
      self!parse-elements($wrapper);
      @elements.push: @($wrapper.nodes);
      $count++;
    }
    %.data<repeat>.delete($attrib);
    %.data.delete($attrib);
    $xml = @elements;
  }
  else {
    $xml = Nil;
  }
}

method !parse-omit-tag ($xml is rw, $tag) {
  my $nodes = $xml.nodes;
  my $query = $xml.attribs{$tag};
  if self.query($query, :bool) {
    $xml = $nodes;
  }
  else {
    $xml.unset: $tag;
  }
}

## Query data.
method query ($query is copy, :$noxml, :$forcexml, :$bool, :$noescape is copy) {
  if $query eq '' { 
    if ($bool) { return True; }
    else       { return '';   }
  }
  if $query eq 'nothing' { 
    if ($bool) { return False; }
    else       { return '';    }
  }
  if $query eq 'default' {
    my $default = @.elements[0].nodes;
    return $default;
  }
  if $query ~~ /^ structure \s+ / {
    $query.=subst(/^ structure \s+ /, '');
    $noescape = True;
  }
  if $query ~~ /^\'(.*?)\'$/ {
    return self.process-query(~$0, :$forcexml, :$noxml, :$noescape);
  } # quoted string, no interpolation.
  if $query ~~ /^<.ident>+\:/ {
    my ($handler, $subquery) = $query.split(/\:\s*/, 2);
    if %!modifiers.exists($handler) {
      ## Modifiers are responsible for subqueries, and calls to process-query.
      return %!modifiers{$handler}(self, $subquery, :$noxml, :$forcexml, :$bool, :$noescape);
    }
  }
  my @paths = $query.split('/');
  my $data = self!lookup(@paths, %.data);
  return self.process-query($data, :$forcexml, :$noxml, :$noescape);
}

## Enforce processing rules for query().
method process-query($data is copy, :$forcexml, :$noxml, :$noescape, :$bool) {
  ## First off, let's escape text, unless noescape is set.
  if (!defined $noescape && $data ~~ Str) {
    $data.=subst('&', '&amp;', :g);
    $data.=subst('<', '&lt;', :g);
    $data.=subst('>', '&gt;', :g);
    $data.=subst('"', '&quot;', :g);
  }
  ## Default rule for forcexml converts non-XML objects into Exemel::Text.
  if ($forcexml) {
    if ($data ~~ Array) {
      for @($data) -> $elm is rw {
        if $elm !~~ Exemel { $elm = Exemel::Text.new(:text(~$elm)); }
      }
      return $data;
    }
    elsif ($data !~~ Exemel) {
      return Exemel::Text.new(:text(~$data));
    }
  }
  elsif ($noxml && $data !~~ Str|Numeric) {
    return; ## With noxml set, we only accept Strings or Numbers.
  }
  return $data;
}

## get-args now supports parameters in the form of {{param name}} for
## when you have nested queries with spaces in them that shouldn't be treated
## as strings, like 'a string' does. It also captures ${vars} and does no
## processing on them unless you are using string processing (see below.)
## It also supports named parameters in the form of :param(value).
## If the :query option is set, all found parameters will be looked up using
## the query() method (with default options.)
## If :query is set to a Hash, then the keys of the Hash represent positional
## parameters (the first positional parameter is 0 not 1.)
## the value represents an action to take, if it is 0, then no querying or
## parsing is done on the value. If it is 1, then the value is parsed as a
## string with any ${name} variables queried.
## If there is a key called .STRING in the query Hash, then parsing as
## strings becomes default, and keys with a value of 1 parse as normal queries.
## so :query({0=>0, 3=>0}) would query all parameters except the 1st and 4th.
## If you specify the :named option, it will always include the %named
## parameter, even if it's empty.
method get-args($string, :$query, :$named, *@defaults) {
  my @result = 
    $string.comb(/ [ '{{'.*?'}}' | '${'.*?'}' | '$('.*?')' | ':'\w+'('.*?')' | \'.*?\' | \S+ ] /);
  @result>>.=subst(/^'{{'/, '');
  @result>>.=subst(/'}}'$/, '');
  @result>>.=subst(:g, /'$('(.*?)')'/, -> $/ { '${'~$0~'}' });
  my %named;
  ## Our nice for loop has been replaced now that we support named
  ## parameters. Oh well, such is life.
  loop (my $i=0; $i < @result.elems; $i++) {
    my $param = @result[$i];
    if $param ~~ /^ ':' (\w+) '(' (.*?) ')' $/ {
      my $key = ~$0;
      my $val = ~$1;
      if $query { $val = self!parse-rules($query, $key, $val); }
      %named{$key} = $val;
      @result.splice($i, 1);
      if $i < @result.elems {
        $i--;
      }
    }
    else {
      if $query { @result[$i] = self!parse-rules($query, $i, $param); }
    }
  }

  my $results = @result.elems - 1;
  my $defs    = @defaults.elems;

  if $results < $defs {
    @result.push: @defaults[$results..$defs-1];
  }
  ## Named params are always last.
  if ($named || (%named.elems > 0)) {
    @result.push: %named;
  }
  return @result;
}

method !parse-rules ($rules, $tag, $value) {
  my $stringy = False;
  if $rules ~~ Hash && $rules.exists('.STRING') {
    $stringy = True;
  }
  if $rules ~~ Hash && $rules.exists($tag) {
    if $rules{$tag} {
      if $stringy {
        return self.query($value);
      }
      else {
        return self.parse-string($value);
      }
    }
    else {
      return $value;
    }
  }
  else {
    if $stringy {
      return self.parse-string($value);
    }
    else {
      return self.query($value);
    }
  }
}

method parse-string ($string) {
  $string.subst(:g, rx/'${' (.*?) '}'/, -> $/ { self.query($0) });
}

## This handles the lookups for query().
method !lookup (@paths is copy, $data) {
  my $path = @paths.shift;
  my $found;
  given $data {
    when Hash {
      if $data.exists($path) {
        $found = .{$path};
      }
    }
    when Array {
      if $path < .elems {
        $found = .[$path];
      }
    }
    default {
      my ($command, *@args) = self.get-args(:query({0=>0}), $path);
      if .can($command) {
        $found = ."$command"(|@args);
      }
      else {
          warn "attempt to access an invalid item '$path'.";
      }
    }
  }
  if @paths {
    return self!lookup(@paths, $found);
  }
  return $found;
}

## Add a single modifier routine.
## Example:
##  use Flower;
##  use Flower::Utils::Perl;
##  my $flower = Flower.new(:file('template.xml'));
##  $flower.add-modifier('evil', &Flower::Utils::Perl::perl_execute);
##
method add-modifier($name, Callable $routine) {
  %!modifiers{$name} = $routine;
}

## Add a bunch of modifiers, mainly used for plugin libraries.
## Expects a Hash, where the key is the name of the modifier, and the
## value is a subroutine reference.
## Example:
##  use Flower;
##  use Flower::Utils::Logic;
##  use Flower::Utils::List;
##  my %mods = Flower::Utils::Logic::export();
##  %mods<sort> = &Flower::Utils::List::list_sort;
##  my $flower = Flower.new(:file('template.xml'));
##  $flower.add-modifiers(%mods);
##
##  Now $flower has all Logic modifiers, plus 'sort'.
##
method add-modifiers(%modifiers) {
  for %modifiers.kv -> $key, $val {
    self.add-modifier($key, $val);
  }
}

## The newest method for loading modifiers.
## Pass it a list of libraries which have export() subs
## and it will load them dynamically. The export() sub must
## return a Hash usable by the add-modifiers() method.
## If the library name doesn't have a :: in it,
## load-modifiers prepends "Flower::Utils::" to it.
## Example:
##  use Flower;
##  my $flower = Flower.new(:file('template.xml'));
##  $flower.load-modifiers('Text', 'Date', 'My::Modifiers');
##
##  Example will load File::Utils::Text, File::Utils::Date and My::Modifiers.
##
method load-modifiers(*@modules) {
  for @modules -> $module {
    my $plugin = $module;
    if $plugin !~~ /'::'/ {
      $plugin = "Flower::Utils::$plugin";
    }
    eval("use $plugin");
    if defined $! { die "use failed: $!"; }
    my $modifiers = eval($plugin~'::export()');
    if defined $! { die "export failed: $!"; }
    self.add-modifiers($modifiers);
  }
}

