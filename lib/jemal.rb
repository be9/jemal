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
    ptr = FFI::MemoryPointer.new :pointer

    mallctl "version", ptr, size_pointer(ptr), nil, 0

    strptr = ptr.read_pointer
    strptr.null? ? nil : strptr.read_string
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

  # Public: Checks if abort-on-warning enabled/disabled.
  #
  # If true, most warnings are fatal. The process will call abort(3) in these
  # cases. This option is disabled by default unless --enable-debug is
  # specified during configuration, in which case it is enabled by default.
  #
  # Returns true if enabled.
  def self.abort?
    get_bool "opt.abort"
  end

  # TODO opt.dss

  # Public: Get virtual memory chunk size (log base 2).
  #
  # If a chunk size outside the supported size range is specified, the size is
  # silently clipped to the minimum/maximum supported size. The default chunk
  # size is 4 MiB (2^22).
  #
  # Examples
  #
  #   Jemal.lg_chunk
  #   # => 22
  #
  # Returns chunk size logarithm.
  def self.lg_chunk
    @lg_chunk ||= get_size_t "opt.lg_chunk"
  end

  # Public: Get maximum number of arenas to use for automatic multiplexing of
  # threads and arenas.
  #
  # The default is four times the number of CPUs, or one if there is a single
  # CPU.
  #
  # Returns Integer number of arenas.
  def self.narenas
    @narenas ||= get_size_t "opt.narenas"
  end
end
