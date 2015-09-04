require 'test_helper'

class JemalTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Jemal::VERSION
  end

  def test_that_it_returns_jemalloc_version
    assert_match /^\d+\.\d+\.\d+/, Jemal.version
  end
end
