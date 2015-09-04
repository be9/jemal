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
    sizeptr = FFI::MemoryPointer.new :size_t

    # FIXME wtf
    case sizeptr.size
    when 8
      sizeptr.write_int64 ptr.size
    when 4
      sizeptr.write_int32 ptr.size
    else
      raise ArgumentError, "Unsupported architecture"
    end

    mallctl "version", ptr, sizeptr, nil, 0

    strptr = ptr.read_pointer
    strptr.null? ? nil : strptr.read_string
  end
end
