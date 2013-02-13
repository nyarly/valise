## Valise

Cascading configuration, made easy in the hopes that it'll be
applied.

## What's it for?

There's a pattern in many Unix applications wherein configuration has a number
of (hopefully) sensible defaults, there's a system-wide config file in /etc
somewhere, each user can have a config file at .coolapprc and sometimes you
even get a per-project configuration file (if that makes sense for the app.)

And that's a thing I really like about many Unix apps, and miss in a lot of
Ruby apps.  But, I recognize, all that config file reading and path handling is
kind of a pain.

Ergo: Valise - the place you keep your files.

## Some nice extras

Valise handles loading and storing data from files, and allows you to define
rules for how cascading works (the default is "first found wins"), as well as
being able to parse YAML documents automatically and merge their contents.

You can automatically populate files - so if a user wants defaults in a project
directory, you can quickly store the current settings there.

Also a nice way to handle template searching.

For more documentation, see: http://nyarly.github.com/valise/
