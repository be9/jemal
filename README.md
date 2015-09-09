# Jemal

This gem provides interface to your MRI built with [jemalloc](canonware.com/jemalloc/).
Of course you heard that
Ruby 2.2.0 [introduced jemalloc support](https://www.ruby-lang.org/en/news/2014/12/25/ruby-2-2-0-released/).

Primary goal of this gem is to provide access to jemalloc statistics.

Currently jemalloc 3.6.0 is supported (certain Ruby gems can't yet be built
with 4.0.0 due to stdbool.h conflict).

## Jemalloc installation

Ubuntu:

    $ sudo apt-get install libjemalloc-dev

OS X:

    $ brew install jemalloc


Note that if you want to use allocation profiling, you'll have to build
jemalloc from source (`./configure --enable-prof`). Both ubuntu and homebrew versions
are built without this option.

## Ruby with jemalloc installation


Instructions are [here](http://groguelon.fr/post/106221222318/how-to-install-ruby-220-with-jemalloc-support).

## Gem installation

Add this line to your application's Gemfile:

```ruby
gem 'jemal'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jemal

## Usage

TODO: Write usage instructions here

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/be9/jemal.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
