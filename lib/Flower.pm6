class Flower;

use Exemel;

## Override find with a subroutine that can find templates based off
## of whatever your needs are (multiple roots, extensions, etc.)
has $.find = sub ($file) {
  if $file.IO ~~ :f { return $file }
}

## Data, is used to store the replacement data. Is available for modifiers.
has %.data is rw;

## Default stores the elements in order of parsing.
## Used to get the 'default' value, and other such stuff.
has @.elements;

## The XML application languages we support.
has @.plugins;

## Add an XML application language plugin.
method add-plugin ($plugin) {
  my $object = self!get-plugin($plugin);
  if $object.defined {
    @.plugins.push: $object;
  }
}

## Add an XML application language plugin, to the beginning of our list.
method insert-plugin ($plugin) {
  my $object = self!get-plugin($plugin);
  if $object.defined {
    @.plugins.unshift: $object;
  }
}

## Return an object instance representing a plugin.
## Can take an object instance or a type object.
method !get-plugin ($plugin) {
  my $object = $plugin;
  if ! $plugin.defined {
    $object = $plugin.new(:flower(self));
  }
  return $object;
}

## The main method to parse a template. Expects an Exemel::Document.
multi method parse (Exemel::Document $template, *%data) {
  ## First we need to set the data, for later re-use.
  %.data = %data;

  ## Let's see if the namespaces has been renamed.
  my %rootattrs;
  for $template.root.attribs.kv -> $key, $val {
    %rootattrs{$val} = $key; ## Yeah, we're reversing it.
  }
  for @.plugins -> $plugin {
    if %rootattrs.exists($plugin.ns) {
      my $tag = %rootattrs{$plugin.ns};
      $tag ~~ s/^xmlns\://;
      $plugin.tag = $tag;
    }
  }

  ## Okay, now let's parse the elements.
  self.parse-element($template.root, :safe);
  return $template;
}

## Parse a template in Exemel::Element form.
multi method parse (Exemel::Element $template, *%data) {
  my $document = Exemel::Document.new(:root($template));
  return self.parse($document, |%data);
}

## Parse a template that is passed as XML text.
multi method parse (Stringy $template, *%data) {
  my $document = Exemel::Document.parse($template);
  if ($document) {
    return self.parse($document, |%data);
  }
}

## Parse a template using a filename. The filename is passed to find().
method parse-file ($filename, *%data) {
  my $file = $.find($filename);
  if $file {
    my $template = Exemel::Document.parse(slurp($file));
    if $template {
      return self.parse($template, |%data);
    }
  }
}

## parse-elements: Parse the child elements of an XML node.
method parse-elements ($xml is rw, $custom-parser?) {
  ## Due to the strange nature of some rules, we're not using the
  ## 'elements' helper, nor using a nice 'for' loop. Instead we're doing this
  ## by hand. Don't worry, it'll all make sense.
  loop (my $i=0; True; $i++) {
    if $i == $xml.nodes.elems { last; }
    my $element = $xml.nodes[$i];
    if $element !~~ Exemel::Element { next; } # skip non-elements.
    @.elements.unshift: $element; ## Stuff the newest element into place.
    if ($custom-parser) {
      $custom-parser($element, $custom-parser);
    }
    else {
      self.parse-element($element);
    }
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

## parse-element: parse a single element.
method parse-element($element is rw, :$safe) {
  ## Let's do this.
  for @.plugins -> $plugin {
    ## First attributes.
    my $defel = False; ## By default we handle XML Attributes, not Elements.
    if $plugin.options.exists('element') {
      $defel = $plugin.options<element>;
    }
    for $plugin.handlers -> $hand {
      my $name;            ## Name of the attribute or element.
      my $meth;            ## Method to call.
      my $issafe = False;  ## Is it safe? Only used if safe mode is in place.
      my $isel = $defel;   ## Is this an element instead of an attribute?
      if $hand ~~ Pair {
        $name  = $hand.key;
        my $rules = $hand.value;
        if $rules ~~ Hash {
          if $rules.exists('method') {
            $meth = $rules<method>;
          }
          if $rules.exists('safe') {
            $issafe = $rules<safe>;
          }
          if $rules.exists('element') {
            $isel = $rules<element>;
          }
        }
        elsif $rules ~~ Str {
          ## If the pair value is a string, it's the method name.
          $meth = $rules; 
        }
      }
      elsif $hand ~~ Str {
        ## If the handler is a string, it's the name of the attribute/element.
        $name = $hand;
      }
      if ! $meth {
        ## If no method has been found by other means, the default is
        ## parse-$name(). E.g. for a name of 'block', we'd call parse-block().
        $meth = "parse-$name";
      }
      if $safe && !$issafe {
        next; ## Skip unsafe handlers.
      }
      if ! $meth { next; } ## Undefined method, we can't handle that.
      my $fullname = $plugin.tag ~ ':' ~ $name;
      if $isel {
        if $element.name eq $fullname {
          $plugin."$meth"($element, $fullname);
        }
      }
      else {
        if $element.attribs.exists($fullname) {
          $plugin."$meth"($element, $fullname);
        }
      }
      if $element !~~ Exemel::Element { last; } ## skip if we changed type.
    } ## /for $plugin.handlers
  } ## /for @.plugins

  ## Okay, now we parse child elements.
  if $element ~~ Exemel::Element {
    self.parse-elements($element);
  }
}

