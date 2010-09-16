class Flower;

use Exemel;

has $.template;

has $!petal is rw = 'petal';
has $!metal is rw = 'metal';
has $!i18n is rw  = 'i18n';

has $!petal_ns = 'http://purl.org/petal/1.0/';
has $!metal_ns = 'http://xml.zope.org/namespaces/metal';
has $!i18n_ns  = 'http://xml.zope.org/namespaces/i18n';

## Override find with a subroutine that can find templates based off
## of whatever your needs are (multiple roots, extensions, etc.)
has $!find;

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
  self.bless(*, :$template, :$find);
}

method !xml-ns($ns is copy) {
  $ns ~~ s/^xmlns\://;
  return $ns;
}

method parse(*%data) {
  ## First, let's see if the namespaces have been renamed.
  for $.template.root.attribs.kv -> $key, $val {
    if $val eq $!petal_ns {
      $!petal = self!xml-ns($key);
    }
    elsif $val eq $!metal_ns {
      $!metal = self!xml-ns($key);
    }
    elsif $val eq $!i18n_ns {
      $!i18n = self!xml-ns($key);
    }
  }
  ## Okay, now let's parse the elements.
  self!parse-elements(%data, $.template.root);
  return ~$.template;
}

method !parse-elements(%data, $xml is rw) {
  for $xml.elements <-> $element {
    if $element.attribs.exists($!petal~':condition') {
      self!parse-condition(%data, $element);
    }
    if $element.attribs.exists($!petal~':define') {
      self!parse-define(%data, $element);
    }
  }
}

method !parse-condition(%data, $xml is rw) {
  ...
}

method !parse-define(%data, $xml is rw) {
  ...
}

