class Flower;

use Exemel;
use Flower::DefaultModifiers;

has $.template;

has $!petal is rw = 'petal';
has $!metal is rw = 'metal';
has $!i18n is rw  = 'i18n';

has $!petal-ns = 'http://purl.org/petal/1.0/';
has $!metal-ns = 'http://xml.zope.org/namespaces/metal';
has $!i18n-ns  = 'http://xml.zope.org/namespaces/i18n';

has @!petal-tags = 'define', 'condition', 'repeat', 'attributes', 'content', 'replace', 'omit-tag';

has @!metal-tags = 'define-macro', 'use-macro', 'define-slot', 'fill-slot';

## Override find with a subroutine that can find templates based off
## of whatever your needs are (multiple roots, extensions, etc.)
has $!find;

## Modifiers, keys are strings, values are subroutines.
has %!modifiers;

## Data, is used to store the replacement data. Is available for modifiers.
has %.data is rw;

method new (:$find is copy, :$file, :$template is copy) {
  if ( ! $file && ! $template ) { die "a file or template must be specified."; }
  if ! $find {
    $find = sub ($file) {
      if $file.IO ~~ :f { return $file; }
    }
  }
  if $file {
    my $filename = $find($file);
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
  my %modifiers = Flower::DefaultModifiers::all();
  self.bless(*, :$template, :$find, :%modifiers);
}

method !xml-ns ($ns is copy) {
  $ns ~~ s/^xmlns\://;
  return $ns;
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
    if $val eq $!petal-ns {
      $!petal = self!xml-ns($key);
    }
    elsif $val eq $!metal-ns {
      $!metal = self!xml-ns($key);
    }
    elsif $val eq $!i18n-ns {
      $!i18n = self!xml-ns($key);
    }
  }

  ## Okay, now let's parse the elements.
  self!parse-elements($.template.root);
  return ~$.template;
}

## parse-elements, currently only does petal items.
## metal will be added in the next major release.
## i18n will be added at some point in the future.
## also TODO: implement 'on-error'.
method !parse-elements ($xml is rw) {
  ## Due to the strange nature of some rules, we're not using the
  ## 'elements' helper, nor using a nice 'for' loop. Instead we're doing this
  ## by hand. Don't worry, it'll all make sense.
  loop (my $i=0; True; $i++) {
    if $i == $xml.nodes.elems { last; }
    my $element = $xml.nodes[$i];
    if $element !~~ Exemel::Element { next; } # skip non-elements.
    for @!petal-tags -> $petal {
      my $tag = $!petal~':'~$petal;
      self!parse-tag($element, $tag, $petal);
      if $element !~~ Exemel::Element { last; } # skip if we changed type.
    }
#    for @metal -> $metal {
#      my $tag = $!metal~':'~$metal;
#      self!parse-tag($element, $tag, $metal);
#    }
    ## Now we clean up removed elements, and insert replacements.
    if ! defined $element {
      $xml.nodes.splice($i--, 1);
    }
    elsif $element ~~ Array {
      $xml.nodes.splice($i--, 1, |$element);
    }
    else {
      if $element ~~ Exemel::Element {
        self!parse-elements($element);
      }
      $xml.nodes[$i] = $element; # Ensure the node is updated.
    }
  }
}

method !parse-tag ($element is rw, $tag, $ns) {
  my $method = 'parse-'~$ns;
  if $element.attribs.exists($tag) {
    self!"$method"($element, $tag);
  }
}

method !parse-define ($xml is rw, $tag) {
  my ($attrib, $query) = $xml.attribs{$tag}.split(/\s+/, 2);
  my $val = self.query($query);
  if defined $val { %.data{$attrib} = $val; }
  $xml.unset($tag);
}

method !parse-condition ($xml is rw, $tag) {
  if self.query($xml.attribs{$tag}) {
    $xml.unset($tag);
  } else {
    $xml = Nil;
  }
}

method !parse-content ($xml is rw, $tag) {
  $xml.nodes.splice;
  my $node = self.query($xml.attribs{$tag});
  if defined $node {
    $xml.nodes.push: $node;
  }
  $xml.unset: $tag;
}

method !parse-replace ($xml is rw, $tag) {
  my $text = $xml.attribs{$tag};
  if defined $text {
    $xml = Exemel::Text.new(:text(self.query($text)));
  }
  else {
    $xml = Nil;
  }
}

method !parse-repeat ($xml is rw, $tag) { ... }

method !parse-omit-tag ($xml is rw, $tag) {
  my $nodes = $xml.nodes;
  my $query = $xml.attribs{$tag};
  if self.query($query) {
    $xml = $nodes;
  }
  else {
    $xml.unset: $tag;
  }
}

## This is a stub, expand it into a proper method.
## Changed it from private to public so that the handler subs
## could call this method.
method query ($query) {
  if $query eq '' { return True; }         # empty text is true.
  if $query eq 'nothing' { return False; } # nothing is false.
  if $query ~~ /<.ident>+\:/ {
    my ($handler, $subquery) = $query.split(/\:\s*/, 2);
    if %!modifiers.exists($handler) {
      return %!modifiers{$handler}(self, $subquery);
    }
  }
  if %.data.exists($query) {
    return %.data{$query} 
  }
  return;
}

## Add a single modifier routine.
method add-modifier($name, Callable $routine) {
  %!modifiers{$name} = $routine;
}

## Add a bunch of modifiers, mainly used for plugin libraries.
## Example:
##  use Flower;
##  use Flower::Utils::Logic;
##  my $flower = Flower.new(:file('template.xml'));
##  $flower.add-modifiers(Flower::Utils::Logic::all());
##
method add-modifiers(%modifiers) {
  for %modifiers.kv -> $key, $val {
    self.add-modifier($key, $val);
  }
}

