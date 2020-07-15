# frozen_string_literal: true

namespace :airbrake do # rubocop:disable Metrics/BlockLength
  desc "Upload private sourcemaps to Airbrake"
  task :upload_private_sourcemaps do
    on roles fetch(:rollbar_role) do
      Dir.chdir fetch(:airbrake_sourcemaps_target_dir) do
        File.join("**", "*.js.map").each do |sourcemap|
          upload_sourcemap(sourcemap)
        end
      end
    end
  end

  def upload_sourcemap(sourcemap)
    uri = URI.parse(
      "https://airbrake.io/api/v4/projects/#{fetch(:airbrake_project_id)}/sourcemaps",
    )

    request = Net::HTTP::Post::Multipart.new(
      uri.path,
      file: UploadIO.new(File.new(sourcemap), "application/octet-stream"),
      name: minified_url_for(sourcemap),
    )

    request["Authorization"] = "Bearer #{fetch(:airbrake_project_key)}"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    res = http.request(request)

    begin
      res.value
    rescue # rubocop:disable Style/RescueStandardError
      info "Failed to upload #{sourcemap} sourcemap. Error #{res.code}: #{res.msg}"
    end
  end

  def minified_url_for(sourcemap)
    gsub_pattern = /\.map\Z/
    url_base = fetch(:airbrake_sourcemaps_minified_url_base).dup
    url_base = url_base.prepend("http://") unless url_base.index(%r{https?:\/\/})

    url = File.join(url_base, sourcemap.gsub(gsub_pattern, ""))
    url
  end
end
