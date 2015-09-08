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

  OPT_BOOL = %i(abort stats_print redzone zero utrace xmalloc tcache
                prof prof_active prof_thread_active_init prof_accum prof_gdump prof_final prof_leak)
  OPT_SIZE_T = %i(lg_chunk narenas quarantine lg_tcache_max lg_prof_sample)
  OPT_SSIZE_T = %i(lg_dirty_mult lg_prof_interval)
  OPT_CHARP = %i(dss junk prof_prefix)

  # Public: Get options (opt.*) as a Hash
  #
  # Returns Hash with 24 options.
  def self.options
    res = {}

    OPT_BOOL.each    { |o| res[o] = get_bool("opt.#{o}") }
    OPT_SIZE_T.each  { |o| res[o] = get_size_t("opt.#{o}") }
    OPT_SSIZE_T.each { |o| res[o] = get_ssize_t("opt.#{o}") }
    OPT_CHARP.each   { |o| res[o] = get_string("opt.#{o}") }

    res
  end

  # Public: Get current number of arenas.
  #
  # Returns Integer value.
  def self.narenas
    get_uint "arenas.narenas"
  end

  def self.arenas_initialized
    n = narenas
    ptr = FFI::MemoryPointer.new :bool, n
    mallctl "arenas.initialized", ptr, size_pointer(ptr), nil, 0

    (0...n).map { |i| ptr.get_uchar(i) > 0 }
  end

  GLOBAL_STATS = %i(allocated active metadata resident mapped)

  def self.stats
    res = {}

    GLOBAL_STATS.each { |s| res[s] = get_size_t("stats.#{s}") }

    res[:cactive] = read_size_t(cactive_ptr)

    ai = arenas_initialized
    res[:arenas] = arenas = Array.new(ai.size)

    ai.each_with_index do |init, i|
      if init
        arenas[i] = arena_stats(i)
      end
    end

    res
  end

  ARN_SIZE_T = %i(pactive pdirty mapped metadata.mapped metadata.allocated)
  ARN_UINT64 = %i(npurge nmadvise purged)

  BIN_PARAMS = %i(allocated nmalloc ndalloc nrequests)
  BIN_SIZES = %i(small large huge)

  def self.arena_stats(i)
    prefix = "stats.arenas.#{i}"

    res = {
      #dss:           get_string("#{prefix}dss"),
      lg_dirty_mult: get_ssize_t("#{prefix}lg_dirty_mult"),
      nthreads:      get_uint("#{prefix}nthreads"),
    }

    ARN_SIZE_T.each { |p| res[p] = get_size_t("#{prefix}#{p}") }
    ARN_UINT64.each { |p| res[p] = get_uint64("#{prefix}#{p}") }

    res[:bins] = bins = {}

    res
  end

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
