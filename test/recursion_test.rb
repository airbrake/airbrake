require File.expand_path '../helper', __FILE__

class RecursionTest < Test::Unit::TestCase
  should "not allow infinite recursion" do
    hash = {:a => :a}
    hash[:hash] = hash
    notice = Airbrake::Notice.new(:parameters => hash)
    assert_equal "[possible infinite recursion halted]", notice.parameters[:hash]
  end
end
