require 'set'
require 'jemal/version'
require 'jemal/interface'

module Jemal
  extend Jemal::Interface

  # Public: Check if Ruby was built with jemalloc.
  #
  # Returns true if it was, false otherwise.
  def self.jemalloc_builtin?
    require 'rbconfig'

    !!(RbConfig::CONFIG["configure_args"] =~ /jemalloc/)
  end

  # Public: Get jemalloc version.
  #
  # Examples
  #
  #   Jemal.version
  #   # => "3.6.0-0-g46c0af68bd248b04df75e4f92d5fb804c3d75340"
  #
  # Returns the String version.
  def self.version
    get_string "version"
  end

  CFG_PARAMS = %i(debug dss fill lazy_lock mremap munmap prof prof_libgcc
                  prof_libunwind stats tcache tls utrace valgrind xmalloc)

  # Public: Get jemalloc build configuration.
  #
  # Returns all config.* parameters in a single Hash.
  #
  # Examples
  #
  #   Jemal.build_configuration
  #   # => {:debug=>false, :dss=>false, :fill=>true, :lazy_lock=>false, ... }
  #
  # Returns a Hash with Symbol keys and boolean values.
  def self.build_configuration
    CFG_PARAMS.inject({}) do |hash, param|
      hash[param] = get_bool("config.#{param}")
      hash
    end
  end

  # Public: Get options (opt.*) as a Hash
  #
  # Returns a Hash with 24 options.
  def self.options
    res = {}

    OPT_BOOL.each    { |o| res[o] = get_bool("opt.#{o}") }
    OPT_SIZE_T.each  { |o| res[o] = get_size_t("opt.#{o}") }
    OPT_SSIZE_T.each { |o| res[o] = get_ssize_t("opt.#{o}") }
    OPT_CHARP.each   { |o| res[o] = get_string("opt.#{o}") }

    res
  end

  OPT_BOOL = %i(abort stats_print redzone zero utrace xmalloc tcache
                prof prof_active prof_accum prof_gdump prof_final prof_leak)
  # 4.0.0: prof_thread_active_init

  OPT_SIZE_T = %i(lg_chunk narenas quarantine lg_tcache_max)
  OPT_SSIZE_T = %i(lg_prof_sample lg_dirty_mult lg_prof_interval)
  OPT_CHARP = %i(dss junk prof_prefix)

  # Public: Get current number of arenas.
  #
  # Returns Integer value.
  def self.arenas_count
    get_uint "arenas.narenas"
  end

  # Public: Get initialized arenas.
  #
  # Returns a Set with integer arena indices. Every index is in
  # [0, arenas_count-1] range.
  def self.initialized_arenas
    n = arenas_count
    ptr = FFI::MemoryPointer.new :bool, n
    mallctl "arenas.initialized", ptr, size_pointer(ptr), nil, 0

    (0...n).inject(Set.new) do |indices, i|
      if ptr.get_uchar(i) > 0
        indices << i
      else
        indices
      end
    end
  end

  # Public: Get various sizes.
  #
  # Page size, bin sizes, large run sizes, etc.
  #
  # Sizes are believed to be constant, therefore this method result is cached.
  # Second and successive calls will return cached value.
  #
  # Returns a Hash with all sizes.
  def self.sizes
    return @sizes if defined?(@sizes)

    res = {
      # Quantum size
      quantum:   get_size_t("arenas.quantum"),
      # Page size
      page_size:  get_size_t("arenas.page"),
      # Maximum thread-cached size class
      tcache_max: get_size_t("arenas.tcache_max"),
      # Total number of thread cache bin size classes.
      nhbins: get_uint("arenas.nhbins")
    }

    # Number of bin size classes.
    nbins = get_uint("arenas.nbins")

    # Total number of large size classes.
    nlruns = get_uint("arenas.nlruns")

    # Total number of huge size classes (4.0.0)
    #nhchunks = get_uint("arenas.nhchunks")

    res[:bins] = (0...nbins).map do |i|
      prefix = "arenas.bin.#{i}."
      {
        # Maximum size supported by size class
        size: get_size_t("#{prefix}size"),
        # Number of regions per page run
        nregs: get_uint32("#{prefix}nregs"),
        # Number of bytes per page run
        run_size: get_size_t("#{prefix}run_size")
      }
    end

    res[:lruns] = (0...nlruns).map do |i|
      # Maximum size supported by this large size class
      get_size_t("arenas.lrun.#{i}.size")
    end

    # 4.0.0
    #res[:hchunks] = (0...nhchunks).map do |i|
      ## Maximum size supported by this huge size class
      #get_size_t("arenas.hchunk.#{i}.size")
    #end

    @sizes = res
  end

  # Public: Get current statistics.
  #
  # Returns stats as one big Hash.
  def self.stats
    res = {}

    GLOBAL_STATS.each { |s| res[s] = get_size_t("stats.#{s}") }
    res[:cactive] = read_size_t(cactive_ptr)

    res[:chunks] = chunks = {}
    CHUNK_STATS.each { |s| chunks[s] = get_size_t("stats.chunks.#{s}") }

    res[:arenas] = arenas = Array.new(arenas_count)

    initialized_arenas.each do |i|
      arenas[i] = arena_stats(i)
    end

    res
  end

  GLOBAL_STATS = %i(allocated active metadata resident mapped)
  CHUNK_STATS  = %i(current total high)

  ARN_SIZE_T = %i(pactive pdirty mapped metadata.mapped metadata.allocated)
  ARN_UINT64 = %i(npurge nmadvise purged)

  BIN_PARAMS = %i(allocated nmalloc ndalloc nrequests)
  BIN_SIZES = %i(small large)

  # Public: Get arena stats.
  #
  # i - the Integer arena index (0..arenas_count-1).
  #
  # Returns stats as a Hash.
  def self.arena_stats(i)
    prefix = "stats.arenas.#{i}."

    res = {
      #dss:           get_string("#{prefix}dss"),
      lg_dirty_mult: get_ssize_t("#{prefix}lg_dirty_mult"),
      nthreads:      get_uint("#{prefix}nthreads"),
    }

    ARN_SIZE_T.each { |p| res[p] = get_size_t("#{prefix}#{p}") }
    ARN_UINT64.each { |p| res[p] = get_uint64("#{prefix}#{p}") }

    BIN_SIZES.each do |sz|
      res[sz] = h = {}

      BIN_PARAMS.each do |p|
        h[p] = get_uint64("#{prefix}#{sz}.#{p}")
      end
    end

    res[:bins] = bins = {}
    bin_sizes = sizes[:bins]

    (0...bin_sizes.size).each do |i|
      binprefix = "#{prefix}bins.#{i}."
      nruns = get_uint64("#{binprefix}nruns")
      next if nruns == 0

      bins[bin_sizes[i][:size]] = {
        # Current number of bytes allocated by bin.
        allocated: get_size_t("#{binprefix}allocated"),

        # Cumulative number of allocations served by bin.
        nmalloc: get_uint64("#{binprefix}nmalloc"),

        # Cumulative number of allocations returned to bin.
        ndalloc: get_uint64("#{binprefix}ndalloc"),

        # Cumulative number of allocation requests.
        nrequests: get_uint64("#{binprefix}nrequests"),

        # Cumulative number of tcache fills.
        nfills: get_uint64("#{binprefix}nfills"),

        # Cumulative number of tcache flushes.
        nflushes: get_uint64("#{binprefix}nflushes"),

        # Cumulative number of times the current run from which to allocate changed.
        nreruns: get_uint64("#{binprefix}nreruns"),

        # Current number of runs.
        curruns: get_size_t("#{binprefix}curruns"),

        # Cumulative number of runs created.
        nruns: nruns
      }
    end

    res[:lruns] = lruns = {}
    lrun_sizes = sizes[:lruns]

    (0...lrun_sizes.size).each do |i|
      lrunprefix = "#{prefix}lruns.#{i}."
      nreqs = get_uint64("#{lrunprefix}nrequests")
      next if nreqs == 0

      lruns[lrun_sizes[i]] = {
        # Cumulative number of allocation requests for this size class served
        # directly by the arena.
        nmalloc: get_uint64("#{lrunprefix}nmalloc"),

        # Cumulative number of deallocation requests for this size class served
        # directly by the arena.
        ndalloc: get_uint64("#{lrunprefix}ndalloc"),

        # Cumulative number of allocation requests for this size class.
        nrequests: nreqs,

        # Current number of runs for this size class.
        curruns: get_size_t("#{lrunprefix}curruns"),
      }
    end

    res
  end

  # Public: Print current stats.
  #
  # Invoke jemalloc's own stats reporting function, which
  # prints all stats to STDERR.
  #
  # Returns nothing.
  def self.stats_print
    malloc_stats_print nil,nil,nil
  end

  protected

  def self.cactive_ptr
    @cactive_ptr ||=
      begin
        ptr = FFI::MemoryPointer.new :pointer
        mallctl "stats.cactive", ptr, size_pointer(ptr), nil, 0
        ptr.read_pointer
      end
  end
end
