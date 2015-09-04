require 'jemal/version'
require 'ffi'

module Jemal
  extend FFI::Library

  ffi_lib [FFI::CURRENT_PROCESS, 'jemalloc']

  # int mallctl(const char *name, void *oldp, size_t *oldlenp,
  #             void *newp, size_t newlen);
  attach_function :mallctl, [:string, :pointer, :pointer, :pointer, :size_t], :int

  # void malloc_stats_print(void (*write_cb) (void *, const char *),
  #                         void *cbopaque, const char *opts);
  # TODO

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

  # Public: Returns jemalloc config.
  #
  # Returns all config.* parameters in a single Hash.
  #
  # Examples
  #
  #   Jemal.config
  #   # => {:debug=>false, :dss=>false, :fill=>true, :lazy_lock=>false, ... }
  #
  # Returns a Hash with Symbol keys and boolean values.
  def self.config
    CFG_PARAMS.inject({}) do |hash, param|
      hash[param] = get_bool("config.#{param}")
      hash
    end
  end

  private

  # Private: Use mallctl to read boolean value.
  #
  # name - the String with parameter name.
  #
  # Returns true or false.
  def self.get_bool(name)
    ptr = FFI::MemoryPointer.new :bool
    mallctl name, ptr, size_pointer(ptr), nil, 0
    ptr.get_uchar(0) > 0
  end

  # Private: Set up a size_t pointer.
  #
  # Creates a pointer to size_t value, which is set to
  # baseptr.size.
  #
  # baseptr - a FFI::MemoryPointer instance.
  #
  # Returns a FFI::MemoryPointer.
  def self.size_pointer(baseptr)
    sizeptr = FFI::MemoryPointer.new :size_t

    case sizeptr.size
    when 8
      sizeptr.write_int64 baseptr.size
    when 4
      sizeptr.write_int32 baseptr.size
    else
      raise ArgumentError, "Unsupported architecture: size_t size = #{sizeptr.size}"
    end

    sizeptr
  end
end
