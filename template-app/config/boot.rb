ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
begin
  require_relative 'initializers/custom_env_vars'
rescue LoadError # the file is not there when installing blocks in CDE
end
