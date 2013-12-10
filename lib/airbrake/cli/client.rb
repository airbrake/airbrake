require File.expand_path( "../runner", __FILE__)

module Client
  extend self

  def options
    Runner.options
  end

  def fetch_projects
    uri = URI.parse "http://#{options.account}.airbrake.io"\
    "/data_api/v1/projects.xml?auth_token=#{options.auth_token}"
    http = Net::HTTP.new(uri.host,uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    response.body
  end

  def create_project
    uri = URI.parse "http://#{options.account}.airbrake.io"\
    "/data_api/v1/projects.xml"
    http = Net::HTTP.new(uri.host,uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data('project[name]' => options.name,'auth_token' => options.auth_token)
    response = http.request(request)
    response.body

    print_project_response(response.body)
  end

  def create_deploy
    uri = URI.parse "http://airbrake.io"\
    "/deploys.txt"
    http = Net::HTTP.new(uri.host,uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    opts = {'deploy[rails_env]' => options.rails_env,"api_key" => options.api_key}
    opts.merge!('deploy[scm_revision]' => options.scm_revision) if options.scm_revision
    request.set_form_data(opts)
    response = http.request(request)
    puts response.body
  end

  def print_projects
    factory = ProjectFactory.new
    projects = fetch_projects
    factory.create_projects_from_xml(projects)
    abort "No projects were fetched. Did you provide the correct auth token?" if projects.match(/error/m)
    puts "\nProjects\n" + "".rjust(63,"#")
    factory.projects.each do |project|
      puts project
    end
    puts
  end

  def print_project_response(response)
    case response
    when /errors/
      puts "Error creating project: #{response.gsub("\n","").scan(/.*<error[^>]*>(.*?)<\/error>.*/).last.first.gsub(/\s{1,}/," ")}"
    when /project/
      project = Project.new(:id => response[/<id[^>]*>(.*?)<\/id>/,1],
                            :name => response[/<name[^>]*>(.*?)<\/name>/,1],
                            :api_key => response[/<api-key[^>]*>(.*?)<\/api-key>/,1])
      puts "\nProject details\n" + "".rjust(63,"#")
      puts project
    else
      puts "Unexpected error. Please try again!\n"
      puts response
    end
  end
end
