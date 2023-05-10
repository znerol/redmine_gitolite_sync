require "json"

namespace :gitolite_sync do

  desc <<-END_DESC
Sync repositories from gitolite

Available options:
  * base_url => base URL of gitolite, e.g. git@gitolite.example.com
  * directory => directory where repositories are mirrored to, defaults to tmp/gitolite

Example:
  rake gitolite_sync:update base_url=git@gitolite.example.com directory=/home/redmine/repos RAILS_ENV="production"
END_DESC

  task :update => :environment do
    raise "base_url is required" if !ENV["base_url"] || ENV["base_url"].empty?

    include Redmine::Utils::Shell

    base_url = ENV["base_url"]
    directory = ENV["directory"] || Rails.root.join("tmp/gitolite")

    info = JSON.parse(`ssh -q #{shell_quote base_url} -- info -json`)
    info["repos"].each_key do |repo|
        repo_path = "#{File.join(directory, repo)}.git"
        repo_url = "#{base_url}:#{repo}"
        if File.directory?(repo_path)
            system("git --git-dir #{shell_quote repo_path} fetch -q")
        else
            system("git clone -q --mirror #{shell_quote repo_url} #{shell_quote repo_path}")
        end
    end

    Rake::Task["redmine:fetch_changesets"].invoke
  end
end
