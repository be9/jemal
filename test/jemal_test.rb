require 'test_helper'
require 'pp'

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

  def test_narenas
    assert_equal true, Jemal.narenas > 0
  end

  def test_options
    assert_equal 24, Jemal.options.size
  end

  def test_stats
    stats = Jemal.stats


    pp stats

    Jemal.stats_print

    pp Jemal.arenas_initialized

    s2 = Jemal.arena_stats(0)
    pp s2
  end
end
