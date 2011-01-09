require File.dirname(__FILE__) + '/helper'

require 'hoptoad_notifier/rails/javascript_notifier'

class JavascriptNotifierTest < Test::Unit::TestCase
  
  def self.after_filter(arg); end
  include ::HoptoadNotifier::Rails::JavascriptNotifier

  should "insert javascript after head" do
    input_body =<<-EOS
<html><head><title></title></head><body></body></html>
    EOS
    javascript = "js-code"
    expected =<<-EOS
<html><head>
js-code
<title></title></head><body></body></html>
    EOS
    output = send :insert_javascript_after_head, input_body, javascript
    assert_equal expected, output
  end

  should "insert javascript after head when head has attributes" do
    input_body =<<-EOS
<html><head lang="en"><title></title></head><body></body></html>
    EOS
    javascript = "js-code"
    expected =<<-EOS
<html><head lang="en">
js-code
<title></title></head><body></body></html>
    EOS
    output = send :insert_javascript_after_head, input_body, javascript
    assert_equal expected, output
  end

end
