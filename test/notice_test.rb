require File.expand_path '../helper', __FILE__


class NoticeTest < Test::Unit::TestCase

  include DefinesConstants

  def configure
    Airbrake::Configuration.new.tap do |config|
      config.api_key = 'abc123def456'
    end
  end

  def build_notice(args = {})
    configuration = args.delete(:configuration) || configure
    Airbrake::Notice.new(configuration.merge(args))
  end

  def stub_request(attrs = {})
    stub('request', { :parameters  => { 'one' => 'two' },
                      :protocol    => 'http',
                      :host        => 'some.host',
                      :request_uri => '/some/uri',
                      :session     => { :to_hash => { 'a' => 'b' } },
                      :env         => { 'three' => 'four' } }.update(attrs))
  end

  def assert_accepts_exception_attribute(attribute, args = {}, &block)
    exception = build_exception
    block ||= lambda { exception.send(attribute) }
    value = block.call(exception)

    notice_from_exception = build_notice(args.merge(:exception => exception))

    assert_equal notice_from_exception.send(attribute),
                 value,
                 "#{attribute} was not correctly set from an exception"

    notice_from_hash = build_notice(args.merge(attribute => value))
    assert_equal notice_from_hash.send(attribute),
                 value,
                 "#{attribute} was not correctly set from a hash"
  end

  def assert_valid_notice_document(document)
    xsd_path = URI(XSD_SCHEMA_PATH)
    schema = Nokogiri::XML::Schema.new(Net::HTTP.get(xsd_path))
    errors = schema.validate(document)
    assert errors.empty?, errors.collect{|e| e.message }.join
  end

  def assert_valid_json(notice)
    json_schema = File.expand_path(File.join(File.dirname(__FILE__),"..", "resources", "airbrake_3_0.json"))
    errors = JSON::Validator.fully_validate(json_schema, notice)
    assert errors.empty?, errors.join
  end

  def build_backtrace_array
    ["app/models/user.rb:13:in `magic'",
      "app/controllers/users_controller.rb:8:in `index'"]
  end

  def hostname
    `hostname`.chomp
  end

  def user
    Struct.new(:email,:id,:name).
      new("darth@vader.com",1,"Anakin Skywalker")
  end

  should "call the cleaner on initialization" do
    cleaner = stub
    cleaner.expects(:clean).returns(stub(:parameters => {}, :cgi_data => {}, :session_data => {}))
    Airbrake::Notice.new(:cleaner => cleaner)
  end

  should "set the api key" do
    api_key = 'key'
    notice = build_notice(:api_key => api_key)
    assert_equal api_key, notice.api_key
  end

  should "accept a project root" do
    project_root = '/path/to/project'
    notice = build_notice(:project_root => project_root)
    assert_equal project_root, notice.project_root
  end

  should "accept a component" do
    assert_equal 'users_controller', build_notice(:component => 'users_controller').controller
  end

  should "alias the component as controller" do
    assert_equal 'users_controller', build_notice(:controller => 'users_controller').component
    assert_equal 'users_controller', build_notice(:component => 'users_controller').controller
  end

  should "accept a action" do
    assert_equal 'index', build_notice(:action => 'index').action
  end

  should "accept a url" do
    url = 'http://some.host/uri'
    notice = build_notice(:url => url)
    assert_equal url, notice.url
  end

  should "set the host name" do
    notice = build_notice
    assert_equal hostname, notice.hostname
  end

  should "accept a backtrace from an exception or hash" do
    array = ["user.rb:34:in `crazy'"]
    exception = build_exception
    exception.set_backtrace array
    backtrace = Airbrake::Backtrace.parse(array)
    notice_from_exception = build_notice(:exception => exception)


    assert_equal backtrace,
                 notice_from_exception.backtrace,
                 "backtrace was not correctly set from an exception"

    notice_from_hash = build_notice(:backtrace => array)
    assert_equal backtrace,
                 notice_from_hash.backtrace,
                 "backtrace was not correctly set from a hash"
  end

  should "accept user" do
    assert_equal user.id, build_notice(:user => user).user.id
    assert_equal user.email, build_notice(:user => user).user.email
    assert_equal user.name, build_notice(:user => user).user.name
  end

  should "pass its backtrace filters for parsing" do
    backtrace_array = ['my/file/backtrace:3']
    exception = build_exception
    exception.set_backtrace(backtrace_array)
    Airbrake::Backtrace.expects(:parse).with(backtrace_array, {:filters => 'foo'})

    Airbrake::Notice.new({:exception => exception, :backtrace_filters => 'foo'})
  end

  should "set the error class from an exception or hash" do
    assert_accepts_exception_attribute :error_class do |exception|
      exception.class.name
    end
  end

  should "set the error message from an exception or hash" do
    assert_accepts_exception_attribute :error_message do |exception|
      "#{exception.class.name}: #{exception.message}"
    end
  end

  should "accept parameters from a request or hash" do
    parameters = { 'one' => 'two' }
    notice_from_hash = build_notice(:parameters => parameters)
    assert_equal notice_from_hash.parameters, parameters
  end

  should "accept session data from a session[:data] hash" do
    data = { 'one' => 'two' }
    notice = build_notice(:session => { :data => data })
    assert_equal data, notice.session_data
  end

  should "accept session data from a session_data hash" do
    data = { 'one' => 'two' }
    notice = build_notice(:session_data => data)
    assert_equal data, notice.session_data
  end

  should "accept an environment name" do
    assert_equal 'development', build_notice(:environment_name => 'development').environment_name
  end

  should "accept CGI data from a hash" do
    data = { 'string' => 'value' }
    notice = build_notice(:cgi_data => data)
    assert_equal data, notice.cgi_data, "should take CGI data from a hash"
  end

  should "not crash without CGI data" do
    assert_nothing_raised do
      build_notice
    end
  end

  should "accept any object that responds to :to_hash as CGI data" do
    hashlike_obj = Object.new
    hashlike_obj.instance_eval do
      def to_hash
        {:i => 'am a hash'}
      end
    end
    assert hashlike_obj.respond_to?(:to_hash)

    notice = build_notice(:cgi_data => hashlike_obj)
    assert_equal({:i => 'am a hash'}, notice.cgi_data, "should take CGI data from any hash-like object")
  end

  should "accept notifier information" do
    params = { :notifier_name    => 'a name for a notifier',
               :notifier_version => '1.0.5',
               :notifier_url     => 'http://notifiers.r.us/download' }
    notice = build_notice(params)
    assert_equal params[:notifier_name], notice.notifier_name
    assert_equal params[:notifier_version], notice.notifier_version
    assert_equal params[:notifier_url], notice.notifier_url
  end

  should "set sensible defaults without an exception" do
    backtrace = Airbrake::Backtrace.parse(build_backtrace_array)
    notice = build_notice(:backtrace => build_backtrace_array)

    assert_equal 'Notification', notice.error_message
    assert_array_starts_with backtrace.lines, notice.backtrace.lines
    assert_equal({}, notice.parameters)
    assert_equal({}, notice.session_data)
  end

  should "use the caller as the backtrace for an exception without a backtrace" do
    filters = Airbrake::Configuration.new.backtrace_filters
    backtrace = Airbrake::Backtrace.parse(caller, :filters => filters)
    notice = build_notice(:exception => StandardError.new('error'), :backtrace => nil)

    assert_array_starts_with backtrace.lines, notice.backtrace.lines
  end

  context "a Notice turned into JSON" do
    setup do
      @exception = build_exception

      @notice = build_notice({
        :notifier_name    => 'a name',
        :notifier_version => '1.2.3',
        :notifier_url     => 'http://some.url/path',
        :exception        => @exception,
        :controller       => "controller",
        :action           => "action",
        :url              => "http://url.com",
        :parameters       => { "paramskey"     => "paramsvalue",
                               "nestparentkey" => { "nestkey" => "nestvalue" } },
        :session_data     => { "sessionkey" => "sessionvalue" },
        :cgi_data         => { "cgikey" => "cgivalue" },
        :project_root     => "RAILS_ROOT",
        :environment_name => "RAILS_ENV"
      })

      @json = @notice.to_json
    end

    should "validate against the JSON schema" do
      assert_valid_json @json
    end
  end

  context "a Notice turned into XML" do
    setup do
      Airbrake.configure do |config|
        config.api_key = "1234567890"
      end

      @exception = build_exception

      @notice = build_notice({
        :notifier_name    => 'a name',
        :notifier_version => '1.2.3',
        :notifier_url     => 'http://some.url/path',
        :exception        => @exception,
        :controller       => "controller",
        :action           => "action",
        :url              => "http://url.com",
        :parameters       => { "paramskey"     => "paramsvalue",
                               "nestparentkey" => { "nestkey" => "nestvalue" } },
        :session_data     => { "sessionkey" => "sessionvalue" },
        :cgi_data         => { "cgikey" => "cgivalue" },
        :project_root     => "RAILS_ROOT",
        :environment_name => "RAILS_ENV"
      })

      @xml = @notice.to_xml

      @document = Nokogiri::XML::Document.parse(@xml)
    end

    should "validate against the XML schema" do
      assert_valid_notice_document @document
    end


    should "serialize a Notice to XML when sent #to_xml" do
      assert_valid_node(@document, "//api-key", @notice.api_key)

      assert_valid_node(@document, "//notifier/name",    @notice.notifier_name)
      assert_valid_node(@document, "//notifier/version", @notice.notifier_version)
      assert_valid_node(@document, "//notifier/url",     @notice.notifier_url)

      assert_valid_node(@document, "//error/class",   @notice.error_class)
      assert_valid_node(@document, "//error/message", @notice.error_message)

      assert_valid_node(@document, "//error/backtrace/line/@number", @notice.backtrace.lines.first.number)
      assert_valid_node(@document, "//error/backtrace/line/@file", @notice.backtrace.lines.first.file)
      assert_valid_node(@document, "//error/backtrace/line/@method", @notice.backtrace.lines.first.method_name)

      assert_valid_node(@document, "//request/url",        @notice.url)
      assert_valid_node(@document, "//request/component", @notice.controller)
      assert_valid_node(@document, "//request/action",     @notice.action)

      assert_valid_node(@document, "//request/params/var/@key",     "paramskey")
      assert_valid_node(@document, "//request/params/var",          "paramsvalue")
      assert_valid_node(@document, "//request/params/var/@key",     "nestparentkey")
      assert_valid_node(@document, "//request/params/var/var/@key", "nestkey")
      assert_valid_node(@document, "//request/params/var/var",      "nestvalue")
      assert_valid_node(@document, "//request/session/var/@key",    "sessionkey")
      assert_valid_node(@document, "//request/session/var",         "sessionvalue")
      assert_valid_node(@document, "//request/cgi-data/var/@key",   "cgikey")
      assert_valid_node(@document, "//request/cgi-data/var",        "cgivalue")

      assert_valid_node(@document, "//server-environment/project-root",     "RAILS_ROOT")
      assert_valid_node(@document, "//server-environment/environment-name", "RAILS_ENV")
      assert_valid_node(@document, "//server-environment/hostname", hostname)
    end
  end

  should "not send empty request data" do
    notice = build_notice
    assert_nil notice.url
    assert_nil notice.controller
    assert_nil notice.action

    xml = notice.to_xml
    document = Nokogiri::XML.parse(xml)
    assert_nil document.at('//request/url')
    assert_nil document.at('//request/component')
    assert_nil document.at('//request/action')

    assert_valid_notice_document document
  end

  %w(url controller action).each do |var|
    should "send a request if #{var} is present" do
      notice = build_notice(var.to_sym => 'value')
      xml = notice.to_xml
      document = Nokogiri::XML.parse(xml)
      assert_not_nil document.at('//request')
    end
  end

  %w(parameters cgi_data session_data).each do |var|
    should "send a request if #{var} is present" do
      notice = build_notice(var.to_sym => { 'key' => 'value' })
      xml = notice.to_xml
      document = Nokogiri::XML.parse(xml)
      assert_not_nil document.at('//request')
    end
  end

  should "not ignore an exception not matching ignore filters" do
    notice = build_notice(:error_class       => 'ArgumentError',
                          :ignore            => ['Argument'],
                          :ignore_by_filters => [lambda { |n| false }])
    assert !notice.ignore?
  end

  should "ignore an wrapped exception matching ignore filters" do
    notice = build_notice(error_class: "NotIgnored",
                          exception_classes: ["Ignored", "NotIgnored"],
                          ignore: ["Ignored"])
    assert notice.ignore?
  end

  should "ignore an exception with a matching error class" do
    notice = build_notice(:error_class => 'ArgumentError',
                          :ignore      => [ArgumentError])
    assert notice.ignore?
  end

  should "ignore an exception with a matching error class name" do
    notice = build_notice(:error_class => 'ArgumentError',
                          :ignore      => ['ArgumentError'])
    assert notice.ignore?
  end

  should "ignore an exception with a matching filter" do
    filter = lambda {|notice| notice.error_class == 'ArgumentError' }
    notice = build_notice(:error_class       => 'ArgumentError',
                          :ignore_by_filters => [filter])
    assert notice.ignore?
  end

  should "not raise without an ignore list" do
    notice = build_notice(:ignore => nil, :ignore_by_filters => nil)
    assert_nothing_raised do
      notice.ignore?
    end
  end

  ignored_error_classes = Airbrake::Configuration::IGNORE_DEFAULT

  ignored_error_classes.each do |ignored_error_class|
    should "ignore #{ignored_error_class} error by default" do
      notice = build_notice(:error_class => ignored_error_class)
      assert notice.ignore?
    end
  end

  should "act like a hash" do
    notice = build_notice(:error_message => 'some message')
    assert_equal notice.error_message, notice[:error_message]
  end

  should "return params on notice[:request][:params]" do
    params = { 'one' => 'two' }
    notice = build_notice(:parameters => params)
    assert_equal params, notice[:request][:params]
  end

  should "ensure #to_hash is called on objects that support it" do
    assert_nothing_raised do
      build_notice(:session => { :object => stub(:to_hash => {}) })
    end
  end

  should "ensure #to_ary is called on objects that support it" do
    assert_nothing_raised do
      build_notice(:session => { :object => stub(:to_ary => []) })
    end
  end

  should "extract data from a rack environment hash" do
    url = "https://subdomain.happylane.com:100/test/file.rb?var=value&var2=value2"
    parameters = { 'var' => 'value', 'var2' => 'value2' }
    env = Rack::MockRequest.env_for(url)

    notice = build_notice(:rack_env => env)

    assert_equal url, notice.url
    assert_equal parameters, notice.parameters
    assert_equal 'GET', notice.cgi_data['REQUEST_METHOD']
  end

  should "show a nice warning when rack environment exceeds rack keyspace" do
    # simulate exception for too big query
    Rack::Request.any_instance.expects(:params).raises(RangeError.new("exceeded available parameter key space"))

    url = "https://subdomain.happylane.com:100/test/file.rb?var=x"
    env = Rack::MockRequest.env_for(url)

    notice = build_notice(:rack_env => env)

    assert_equal url, notice.url
    assert_equal({:message => "failed to call params on Rack::Request -- exceeded available parameter key space"}, notice.parameters)
    assert_equal 'GET', notice.cgi_data['REQUEST_METHOD']
  end

  should "extract data from a rack environment hash with action_dispatch info" do
    params = { 'controller' => 'users', 'action' => 'index', 'id' => '7' }
    env = Rack::MockRequest.env_for('/', { 'action_dispatch.request.parameters' => params })

    notice = build_notice(:rack_env => env)

    assert_equal params, notice.parameters
    assert_equal params['controller'], notice.component
    assert_equal params['action'], notice.action
  end

  should "extract session data from a rack environment" do
    session_data = { 'something' => 'some value' }
    env = Rack::MockRequest.env_for('/', 'rack.session' => session_data)

    notice = build_notice(:rack_env => env)

    assert_equal session_data, notice.session_data
  end

  should "prefer passed session data to rack session data" do
    session_data = { 'something' => 'some value' }
    env = Rack::MockRequest.env_for('/')

    notice = build_notice(:rack_env => env, :session_data => session_data)

    assert_equal session_data, notice.session_data
  end

  should "prefer passed error_message to exception message" do
    exception = build_exception
    notice = build_notice(:exception => exception,:error_message => "Random ponies")
    assert_equal "BacktracedException: Random ponies", notice.error_message
  end
end
