# Valise

### Cascading configuration made easy.

## What's it for?

There's a pattern in many Unix applications where configuration has a number
of (hopefully) sensible defaults, there's a system-wide config file in /etc
somewhere, each user can have a config file at .coolapprc and sometimes you
even get a per-project configuration file (if that makes sense for the app.)

For instance, `git` does something like this, with ~/.gitconfig and per-project
.git directories. `bash` works this way, with /etc/bashrc and ~/.bashrc.

It's a really helpful pattern used in many Unix apps, especially since it makes
complex flexible configuration much easier to grasp.  I miss it in a lot of
Ruby apps.  All that config file reading and path handling is kind of a
pain.

Enter Valise, a library to provide a standard, very powerful set of tools
to load files from a cascading set of directories.

## Usage

### Installation

Add

```ruby
gem 'valise'
```
to your Gemfile or

```ruby
spec.add_dependency "valise"
```
to your gemspec and

```ruby
bundle install
```

### Setup

First, we need to create a `Valise::Set` - a search path for files.

```ruby
require 'valise'

file_set = Valise::Set.define do
  rw ".myapp"
  rw "~/.myapp"
  rw "/usr/share/myapp"
  rw "/etc/myapp"
  ro from_here("../../../default-configuration")
end
```

This describes for Valise a list of directories to search, from first to last,
when we're looking for a file. The difference between `ro` and `rw` has to do
with when we're writing files - we'll get to that later.

The `from_here` call makes it easy to refer to a directory relative to the
current code file, so that instead of treating defaults as a special hard coded
case you can write, for example, a default configuration file and have it be
loaded if it hasn't been replaced.

### Finding files

Once we have a `Valise::Set` defined, there are a number of handy things we can
do with it.

```ruby
file_set.contents("config.txt")
```
will load the contents from the top-most "config.txt" file. This is pretty much
the bread and butter of Valise.

### Using File items

There are a number of more powerful tools provided, with a slightly different
API:
```ruby
config_file = file_set.find("config.txt")
config_file.full_path #=> e.g.  /home/nice_user/.myapp/config.txt
config_file.raw_file #=> an open File object
config_file.contents = "A new string" #<- writes new content
```

### Automatic YAML handling

The default behavior for Valise is to find the topmost existant file and treat
its contents as a simple string. However, if you change your set definition
slightly:

```ruby
file_set = Valise::Set.define do
  rw ".myapp"
  rw "~/.myapp"
  rw "/etc/myapp"

  handle "*.yml", :yaml, :hash_merge
  handle "*.yaml", :yaml, :hash_merge
end
```

Now, if you have

`~/.myapp/config.yml`
```yaml
---
configured: well
revision: 101
```

you can do:
```ruby
file_set.contents("config.yml") #=> { "configured" => "well", "revision" => 101 }
```

Likewise, you can work with the Hash, and then
`file_set.find("config.yml").contents = new_hash` will write a YAML document.

Better still, Valise will merge multiple files this way, so your users can have
a set of defaults in their home directory and override them on a per-project
basis.

### Automatic Template Handling

If you also add the `tilt` gem to your project, Valise will allow you to say
something like

```ruby
template_sets = file_set.templates("views")
template_sets.contents("template") #=> a Tilt::Erb template, ready for #render(context)
```

Note that in the above, the template data will be loaded from
"views/template.erb", which leads us to...

### Manipulating Sets

Valise::Sets can be manipulated in a number of ways.

The simplest is concatenation: you can say `dynamic_set + fixed_set` and get a
new set that will search the paths of `dynamic_set` and then `fixed_set`.

#### Subsets

You can organize your file searching by producing so-called "sub_sets"

```ruby
file_set.sub_set("controllers") #=> a new Valise::Set
```

The new Set is just like you'd built it from scratch by adding "/controllers"
to the end of all your search paths. This is really useful when you have a base
set, and then have use cases for finding and using different sets of files.

#### Prefixes and Extensions

You can also set up sets that search for files over a list of extensions:

```ruby
file_set.exts(".yml", ".yaml").contents("config")
```

This'll search in e.g. `.myapp/config.yml", then ".myapp/config.yaml", then
"~/.myapp/config.yml" and so on.

Likewise, you can say:

```ruby
file_set.pfxs("_", "")
```
which'll get you a Rails-style search for _partials and then normal templates.

#### Stemming

The most sophisticated tool for manipulating Sets is "stemming." (For
'sophisticated' read "difficult to understand" and "infrequently used")

Think of stemming as the converse to sub-sets - while the sub-set path is
implicitly added to search terms, a stem is implicitly _removed_.

```
file_set.stemmed("weird").contents("weird/config.yaml") #=> contents from .myapp/config.yaml
```

#### All Together Now

The above manipulations can all be combined to produce and compose really
sophisticated views onto the file system. In fact,
`file_set.templates("views")` is actually

```ruby
template_types = ::Tilt.mappings.keys
new_set = self.sub_set("views")
new_set = new_set.pfxs("", "_")
new_set = new_set.exts(template_types.map{|k| ".#{k}"})
template_types.each do |type|
  new_set.add_serialization_handler("**.#{mapping}", :tilt)
end
```

### Iteration

Core to the API metaphor for Valise is that once you've built a file set, you
should be able to consider it as effectively a single directory. One way this
is obvious is that you can:

```ruby
file_set.files do |item|
  puts item.full_path, item.contents
end
#or
file_set.glob('**.rb') do |ruby_file|
  puts ruby_file.full_path
end
```

#### Population

You can also use Valise to quickly create a bunch of files:

```ruby
file_set.populate
```

is a convenience for looping over all the files in the set and copying them to
the top-most writable directory. Since you can set up the file_set to be a
complex view onto the filesystem, this means you can gather up files from all
over quickly.

## Design Philosophy

There are a few guiding principles to Valise.

First is that to use Valise you only need to know one class name: Valise::Set.
Every other object is the return value of a method on another.

Second is that methods should return new values rather than mutate their
receivers. For instance, Set#sub_set creates a new set rather than change the
set it's called on. This makes it easier to reason about the changes you're
making and to compose and reuse Valise objects.

Third is that every operation in Valise is either very simple or built up from
other operations. Set#templates is a good example of this. I've gone to some
lengths to avoid complex operations being special cases, so that the mechanisms
built up to support specific use cases can be reused elsewhere.


## Known Bugs

While Valise is quite usable and useful, it's far from perfect.

There remain some advanced use cases that can be quite tricky to implement -
the more common of these need decent convenience functions.

There are places where the design drifts from its ideals - the
Set#add_serializer method mutates the underlying set for instance.

There are also a couple of places where two different approaches are used to
accomplish related goals, which I'm afraid complicates a deep understanding of
the code. Specifically, sub_set and stemming work by transforming the
underlying set, but Set#exts and Set#pfxs work by wrapping decorators around
the sets. It may be that it would be better to rebuild the former features as
decorators - I think the behaviors would more closely match what might be
desired there.

For more documentation, see: http://nyarly.github.com/valise/ (although this
may not be 100% up to date.)

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md)

## Credits

Created and maintained by Judson Lester (@nyarly)

## License

MIT license, c.f. [LICENSE](LICENSE)
