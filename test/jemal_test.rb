require 'test_helper'
require 'pp'
require 'log_buddy'

class JemalTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Jemal::VERSION
  end

  def test_that_ruby_was_built_with_jemalloc
    assert_equal true, Jemal.jemalloc_builtin?
  end

  def test_that_it_returns_jemalloc_version
    assert_match /^\d+\.\d+\.\d+/, Jemal.version
  end

  def test_build_configuration
    cfg = Jemal.build_configuration

    assert_kind_of Hash, cfg

    assert_equal cfg.keys.sort, Jemal::CFG_PARAMS.sort

    cfg.values.each do |v|
      assert_includes [true, false], v
    end
  end

  def test_options
    assert_equal 22, Jemal.options.size
  end

  def test_arenas_count
    assert_operator Jemal.arenas_count, :>, 0
  end

  def test_initialized_arenas
    ia = Jemal.initialized_arenas

    count = Jemal.arenas_count

    assert_kind_of Set, ia
    assert_operator ia.size, :<=, count

    ia.each do |idx|
      assert_operator 0, :<=, idx
      assert_operator idx, :<, count
    end
  end

  def test_sizes
    sz = Jemal.sizes

    assert_operator sz[:quantum],    :>, 0
    assert_operator sz[:page_size],  :>, 0
    assert_operator sz[:tcache_max], :>, 0
    assert_operator sz[:nhbins],     :>, 0

    assert_kind_of Array, sz[:bins]
    assert_operator sz[:bins].size,  :>, 0

    b = sz[:bins].first
    assert_kind_of Hash, b
    assert_operator b[:size], :>, 0
    assert_operator b[:nregs], :>, 0
    assert_operator b[:slab_size], :>, 0
  end

  def test_sizes_caching
    sz1 = Jemal.sizes
    sz2 = Jemal.sizes

    assert_same sz1, sz2
  end

  def test_stats
    s = Jemal.stats

    assert_operator s[:allocated], :>, 0
    assert_operator s[:active],    :>, 0
    assert_operator s[:metadata],  :>=, 0
    assert_operator s[:resident],  :>=, 0
    assert_operator s[:mapped],    :>, 0

    assert_kind_of Array, s[:arenas]
    assert_equal Jemal.initialized_arenas.size, s[:arenas].size
  end

  def test_arena_stats
    s = Jemal.arena_stats(Jemal.initialized_arenas.first)

    assert_operator s[:lg_dirty_mult], :>=, 0
    assert_operator s[:nthreads], :>, 0
    assert_operator s[:pactive], :>, 0
    assert_operator s[:pdirty], :>=, 0
    assert_operator s[:mapped], :>, 0
    assert_operator s[:"metadata.mapped"], :>=, 0
    assert_operator s[:"metadata.allocated"], :>=, 0

    assert_operator s[:npurge], :>=, 0
    assert_operator s[:nmadvise], :>=, 0
    assert_operator s[:purged], :>=, 0

    ss = s[:small]
    assert_kind_of Hash, ss

    assert_operator ss[:allocated], :>, 0
    assert_operator ss[:nmalloc], :>, 0
    assert_operator ss[:ndalloc], :>, 0
    assert_operator ss[:nrequests], :>, 0

    sl = s[:large]
    assert_kind_of Hash, sl

    assert_operator sl[:allocated], :>, 0
    assert_operator sl[:nmalloc], :>, 0
    assert_operator sl[:ndalloc], :>, 0
    assert_operator sl[:nrequests], :>, 0

    assert_kind_of Hash, s[:bins]

    # TODO test bins and lruns contents
  end

  def test_stats_print
    out, err = capture_subprocess_io do
      Jemal.stats_print
    end

    assert_match /jemalloc statistics/, err
  end
end
