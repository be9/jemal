# Jemal

This gem provides interface to your MRI built with [jemalloc](canonware.com/jemalloc/).
Of course you heard that
Ruby 2.2.0 [introduced jemalloc support](https://www.ruby-lang.org/en/news/2014/12/25/ruby-2-2-0-released/).

Primary goal of this gem is to provide access to jemalloc statistics.

Currently jemalloc 3.6.0 is supported (certain Ruby gems can't yet be built
with 4.0.0 due to stdbool.h conflict).

Note that there's another [jemalloc-related gem](https://github.com/kzk/jemalloc-rb) on RubyGems.
It doesn't provide interface to builtin jemalloc, but rather aims at injecting jemalloc in runtime with LD_PRELOAD.

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

To be sure that your Ruby is jemalloc-powered, use `Jemal.jemalloc_builtin?`.

```ruby
require 'jemal'

Jemal.jemalloc_builtin?
# => true
```

You can also check jemalloc version:

```ruby
Jemal.version
# => "3.6.0-0-g46c0af68bd248b04df75e4f92d5fb804c3d75340"
```

Look at the flags jemalloc has been built with:

```ruby
Jemal.build_configuration
# => {:debug=>false, :dss=>false, :fill=>true, :lazy_lock=>false, :mremap=>false, :munmap=>true,
#     :prof=>false, :prof_libgcc=>false, :prof_libunwind=>false, :stats=>true, :tcache=>true,
#     :tls=>false, :utrace=>false, :valgrind=>false, :xmalloc=>false}
```

Most of these options aren't very interesting, however be sure that `Jemal.build_configuration[:stats]` is `true`,
otherwise you won't be able to collect statistics.

Find out how many arenas are used by jemalloc:

```ruby
Jemal.arenas_count
# => 16
```

Each arena is basically a separate allocator with its own memory. Multiple arenas provide more speed for heavily
multithreaded applications by allowing parallel threads to allocate memory simultaneously. This doesn't help MRI much, because its heap is still shared between all threads, so we can set `MALLOC_CONF=narenas:1` in environment and have single arena.

Now to statistics:

```ruby
Jemal.stats
# => {:allocated=>23587776, :active=>24416256, :metadata=>0, :resident=>0, :mapped=>29360128,
#     :cactive=>37748736, :chunks=>{:current=>7, :total=>7, :high=>7},
#     :arenas=>[ ... ]}
```

The returned hash is quite big, it contains joint statistics, as well as statistics for each arena. Read 
[jemalloc man page](http://www.unix.com/man-page/freebsd/3/jemalloc/) to be able to understand the figures (look for `stats.*`).

If you just want human-compatible stats in text form and `STDERR` is okay, you are also covered:

```ruby
Jemal.stats_print
```

You'll get a jemalloc stats dump which looks like this:

```
___ Begin jemalloc statistics ___
Version: 3.6.0-0-g46c0af68bd248b04df75e4f92d5fb804c3d75340
Assertions disabled
Run-time option settings:
  opt.abort: false
  opt.lg_chunk: 22
  opt.dss: "secondary"
  opt.narenas: 16
  opt.lg_dirty_mult: 3
  opt.stats_print: false
  opt.junk: false
  opt.quarantine: 0
  opt.redzone: false
  opt.zero: false
  opt.tcache: true
  opt.lg_tcache_max: 15
CPUs: 4
Arenas: 16
Pointer size: 8
Quantum size: 16
Page size: 4096
Min active:dirty page ratio per arena: 8:1
Maximum thread-cached size class: 32768
Chunk size: 4194304 (2^22)
Allocated: 23781096, active: 25649152, mapped: 33554432
Current active ceiling: 37748736
chunks: nchunks   highchunks    curchunks
              8            8            8
huge: nmalloc      ndalloc    allocated
            0            0            0

arenas[0]:
assigned threads: 1
dss allocation precedence: disabled
dirty pages: 6262:52 active:dirty, 0 sweeps, 0 madvises, 0 purged
            allocated      nmalloc      ndalloc    nrequests
small:       17493736       317316       120581       678822
large:        6287360          432           56         1269
total:       23781096       317748       120637       680091
active:      25649152
mapped:      29360128
bins:     bin  size regs pgs    allocated      nmalloc      ndalloc    nrequests       nfills     nflushes      newruns       reruns      curruns
            0     8  501   1        87688        12194         1233        19899          246           25           23           32           23
            1    16  252   1       200480        22361         9831        31078          279          113           81          162           52
            2    32  126   1      1017088        36067         4283        81314          433           57          267          373          264
            3    48   84   1      4174848       137466        50490       250234         1644          603         1140         3707         1072
            4    64   63   1       331392         9969         4791        35396          335           98          115          273          104
            5    80   50   1       691840        14013         5365        52709          353          122          197          682          182
            6    96   84   2       269664         3921         1112        12273           87           47           45           55           40
            7   112   72   2       433664         4481          609         7083           95           32           61           65           57
            8   128   63   2       207488         2086          465        11407           84           35           32           42           28
            9   160   51   2      2482880        49495        33977       106753          997          672          486         2895          313
           10   192   63   3       205632         1643          572         3659           61           42           24           24           19
           11   224   72   4       422688         2339          452         3222           62           35           31           17           28
           12   256   63   4       152320         1049          454         1383           51           39           19           11           11
           13   320   63   5      2549760         8587          619        11026          179           27          135           39          132
           14   384   63   6       167040          749          314         1105           29           38           11            3            8
           15   448   63   7       689472         2861         1322         5053          227           51           38           39           29
           16   512   63   8       161280          551          236          552           35           35           11            5            6
           17   640   51   8       693120         3729         2646        39605          119           74           42          224           25
           18   768   47   9       328704          677          249          723           36           36           15            8           10
           19   896   45  10       272384          560          256          660           36           35           14            9            7
           20  1024   63  16       273408          475          208          464           31           37            7            4            5
           21  1280   51  16       478720          686          312         1367           39           38           14            9            8
           22  1536   42  16       259584          323          154          545           40           34            6            3            5
           23  1792   38  17       236544          304          172          454           30           30            7            5            4
           24  2048   65  33       182272          236          147          198           29           30            3            1            2
           25  2560   52  33       245760          227          131          393           24           30            4            1            3
           26  3072   43  33       181248          156           97          173           30           30            3            7            2
           27  3584   39  35        96768          111           84           94           21           24            2            0            1
large:   size pages      nmalloc      ndalloc    nrequests      curruns
         4096     1           63           21          520           42
         8192     2           89           17          465           72
        12288     3           21            9           23           12
        16384     4          243            3          244          240
        20480     5            2            2            2            0
        24576     6            2            2            2            0
        28672     7            3            1            3            2
        32768     8            6            1            7            5
[11]
        81920    20            1            0            1            1
[2]
        94208    23            1            0            1            1
[232]
      1048576   256            1            0            1            1
[762]
--- End jemalloc statistics ---
```

Other methods of less interest:

```ruby
Jemal.options       # Returns runtime jemalloc options
# => { :abort=>false, ... }

Jemal.sizes         # Returns some constant sizes (page, bin, lrun)
# => { :page_size=>4096, ... }
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/be9/jemal.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
