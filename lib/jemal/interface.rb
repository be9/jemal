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
    attach_function :malloc_stats_print, [:pointer, :pointer, :pointer], :void

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

    # Private: Use mallctl to read unsigned value.
    #
    # name - the String with parameter name.
    #
    # Returns Numeric value.
    def get_uint(name)
      ptr = FFI::MemoryPointer.new :uint
      mallctl name, ptr, size_pointer(ptr), nil, 0

      ptr.read_uint
    end

    # Private: Use mallctl to read unsigned 32-bit value.
    #
    # name - the String with parameter name.
    #
    # Returns Numeric value.
    def get_uint32(name)
      ptr = FFI::MemoryPointer.new :uint32
      mallctl name, ptr, size_pointer(ptr), nil, 0
      ptr.read_uint32
    end

    # Private: Use mallctl to read unsigned 64-bit value.
    #
    # name - the String with parameter name.
    #
    # Returns Numeric value.
    def get_uint64(name)
      ptr = FFI::MemoryPointer.new :uint64
      mallctl name, ptr, size_pointer(ptr), nil, 0
      ptr.read_uint64
    end

    # Private: Use mallctl to write unsigned 64-bit value.
    #
    # name - the String with parameter name.
    #
    # Returns nothing.
    def write_uint64(name, value)
      ptr = FFI::MemoryPointer.new :uint64
      ptr.write_uint64 value
      mallctl name, nil, nil, ptr, ptr.size
    end

    # Private: Use mallctl to read size_t value.
    #
    # name - the String with parameter name.
    #
    # Returns Numeric value.
    def get_size_t(name)
      ptr = FFI::MemoryPointer.new :size_t
      mallctl name, ptr, size_pointer(ptr), nil, 0

      read_size_t(ptr)
    end

    # Private: Use mallctl to read size_t value.
    #
    # name - the String with parameter name.
    #
    # Returns Numeric value.
    def get_ssize_t(name)
      ptr = FFI::MemoryPointer.new :ssize_t
      mallctl name, ptr, size_pointer(ptr), nil, 0

      read_ssize_t(ptr)
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
      write_size_t(sizeptr, baseptr.size)
      sizeptr
    end

    case FFI::Platform::ADDRESS_SIZE
    when 64
      def read_size_t(ptr)
        ptr.read_uint64
      end

      def write_size_t(ptr, value)
        ptr.write_uint64 value
      end

      def read_ssize_t(ptr)
        ptr.read_int64
      end

    when 32
      def read_size_t(ptr)
        ptr.read_uint32
      end

      def write_size_t(ptr, value)
        ptr.write_uint32 value
      end

      def read_ssize_t(ptr)
        ptr.read_int32
      end

    else
      raise "Unsupported platform address size = #{FFI::Platform::ADDRESS_SIZE}"
    end
  end
end
