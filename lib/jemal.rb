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
end
