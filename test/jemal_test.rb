require 'test_helper'

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

  def test_abort
    ab = Jemal.abort?

    assert_includes [true, false], ab
  end
end
