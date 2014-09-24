require File.expand_path '../helper', __FILE__

class ExceptionWrapperTest < Test::Unit::TestCase
  context "error_class" do
    should "equal the class name of the exception" do
      ex = RuntimeError.new
      exw = Airbrake::ExceptionWrapper.new(ex, nil)

      assert_equal 'RuntimeError', exw.error_class
    end

    should "allow override" do
      ex = RuntimeError.new
      exw = Airbrake::ExceptionWrapper.new(ex, nil, :error_class => 'some other class')

      assert_equal 'some other class', exw.error_class
    end

    should "be nil with no exception" do
      exw = Airbrake::ExceptionWrapper.new(nil, nil)
      assert_nil exw.error_class
    end
  end

  context "#error_message" do
    should 'prepend the error class if present' do
      ex = RuntimeError.new
      exw = Airbrake::ExceptionWrapper.new(ex, nil, :error_class => 'prepend me')

      assert_equal 'prepend me: RuntimeError', exw.error_message
    end

    should 'use the text from the exception' do
      ex = RuntimeError.new('NO!!')
      exw = Airbrake::ExceptionWrapper.new(ex, nil)
      
      assert_equal 'RuntimeError: NO!!', exw.error_message
    end

    should 'be "Notification" if there\'s no exception and no error message in the args' do
      exw = Airbrake::ExceptionWrapper.new(nil, nil)
      
      assert_equal 'Notification', exw.error_message
    end

    should 'be "Notification" with prefix if there\'s no exception and no error message in the args but with a error class set' do
      exw = Airbrake::ExceptionWrapper.new(nil, nil, error_class: 'prepend this')
      
      assert_equal 'prepend this: Notification', exw.error_message
    end

    should 'be the custom error message passed in the args' do
      exw = Airbrake::ExceptionWrapper.new(nil, nil, error_message: 'BE AWARE')
      
      assert_equal 'BE AWARE', exw.error_message
    end
  end

  context '#backtrace' do
    should 'use the exception backtrace when present' do
      ex = RuntimeError.new("buh!")
      ex.set_backtrace ["imma_ghost.rb:321:in `stuff'"]
      exw = Airbrake::ExceptionWrapper.new(ex, nil, error_message: 'BE AWARE')

      assert_equal "imma_ghost.rb:321:in `stuff'", exw.backtrace.lines.first.to_s
    end

    should 'use the provided :backtrace when no exception is present' do
      exw = Airbrake::ExceptionWrapper.new(nil, nil, backtrace: ['imma.rb:321:in `unicorn\''])

      assert_equal "imma.rb:321:in `unicorn'", exw.backtrace.lines.first.to_s
    end

    should 'use the provided :backtrace when the provided exception has no backtrace' do
      ex = RuntimeError.new("buh!")
      exw = Airbrake::ExceptionWrapper.new(ex, nil, backtrace: ['imma.rb:321:in `unicorn\''])

      assert_equal "imma.rb:321:in `unicorn'", exw.backtrace.lines.first.to_s
    end

    should 'use the calling context when there\'s no exception and no custom backtrace' do
      exw = Airbrake::ExceptionWrapper.new(nil, nil)
      assert_match /exception_wrapper_test.rb/, exw.backtrace.lines.first.to_s
      assert_match /ExceptionWrapperTest/, exw.backtrace.lines.first.to_s
    end

  end

  context "#to_hash" do
    should 'return a hash representation of the exception' do
      ex = RuntimeError.new("buh!")
      ex.set_backtrace ["codes.rb:1234:in `fix_the_universe'"]
      exw = Airbrake::ExceptionWrapper.new(ex, nil, error_message: 'BE AWARE')

      assert_equal({
          :type => 'RuntimeError',
          :message => 'RuntimeError: BE AWARE',
          :backtrace => [
            {
              :file     =>  'codes.rb', 
              :line     =>  1234, 
              :function =>  'fix_the_universe'
            }
          ]
        }, exw.to_hash)
    end
  end
end