require File.expand_path( "../project", __FILE__)
# Responsible for creating projects when needed.
# Creates them from XML received.
class ProjectFactory
  def initialize
    @project = Project.new
    @projects = []
  end

  def project
    @project
  end

  def create_projects_from_xml(xml)
    xml.split("\n").each do |line|
      /<name[^>]*>(?<name>.*?)<\/name>/ =~ line
      project.name    = name.capitalize if name
      /<id[^>]*>(?<id>.*?)<\/id>/ =~ line
      project.id      = id              if id
      /<api-key[^>]*>(?<api_key>.*?)<\/api-key>/ =~ line
      project.api_key = api_key         if api_key
      check_project
    end
  end

  def check_project
    if @project.valid?
      projects << @project
      @project = Project.new
    end
  end

  def projects
    @projects
  end
end
