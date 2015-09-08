require 'ffi'

module Jemal
  module Interface
    extend FFI::Library

    ffi_lib [FFI::CURRENT_PROCESS, 'jemalloc']

    # int mallctl(const char *name, void *oldp, size_t *oldlenp,
    #             void *newp, size_t newlen);
    attach_function :mallctl, [:string, :pointer, :pointer, :pointer, :size_t], :int

    # void malloc_stats_print(void (*write_cb) (void *, const char *),
    #                         void *cbopaque, const char *opts);
    # TODO


    protected

    # Private: Use mallctl to read boolean value.
    #
    # name - the String with parameter name.
    #
    # Returns true or false.
    def get_bool(name)
      ptr = FFI::MemoryPointer.new :bool
      mallctl name, ptr, size_pointer(ptr), nil, 0
      ptr.get_uchar(0) > 0
    end

    # Private: Use mallctl to read size_t value.
    #
    # name - the String with parameter name.
    #
    # Returns Numeric value.
    def get_size_t(name)
      ptr = FFI::MemoryPointer.new :size_t
      mallctl name, ptr, size_pointer(ptr), nil, 0

      case ptr.size
      when 8
        ptr.read_uint64
      when 4
        ptr.read_uint32
      else
        raise ArgumentError, "Unsupported architecture: size_t size = #{ptr.size}"
      end
    end

    # Private: Use mallctl to read size_t value.
    #
    # name - the String with parameter name.
    #
    # Returns Numeric value.
    def get_ssize_t(name)
      ptr = FFI::MemoryPointer.new :ssize_t
      mallctl name, ptr, size_pointer(ptr), nil, 0

      case ptr.size
      when 8
        ptr.read_int64
      when 4
        ptr.read_int32
      else
        raise ArgumentError, "Unsupported architecture: ssize_t size = #{ptr.size}"
      end
    end

    # Private: Use mallctl to read string value.
    #
    # name - the String with parameter name.
    #
    # Returns String or nil.
    def get_string(name)
      ptr = FFI::MemoryPointer.new :pointer

      mallctl name, ptr, size_pointer(ptr), nil, 0

      strptr = ptr.read_pointer
      strptr.null? ? nil : strptr.read_string
    end

    # Private: Set up a size_t pointer.
    #
    # Creates a pointer to size_t value, which is set to
    # baseptr.size.
    #
    # baseptr - a FFI::MemoryPointer instance.
    #
    # Returns a FFI::MemoryPointer.
    def size_pointer(baseptr)
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
end
