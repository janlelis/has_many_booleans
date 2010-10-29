require 'rubygems'
gem 'activesupport', '>=3.0.0'
require 'active_support'
require 'active_support/test_case'
gem 'activerecord', ">=3.0.0"
require 'active_record'
require 'rails'
require 'logger'

# # #
# setup test environment
#
ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.dirname(__FILE__) + '/../../../..'

require 'test/unit'
#require File.expand_path(File.join(ENV['RAILS_ROOT'], 'config/environment.rb'))

def load_schema
  config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
  ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
  db_adapter ||= begin
    require 'sqlite'
    'sqlite'
  rescue MissingSourceFile
    begin
      require 'sqlite3'
      'sqlite3'
       rescue MissingSourceFile
     end
  end

  if !db_adapter
    raise "No DB Adapter selected.Please install Sqlite or Sqlite3."
  end

  ActiveRecord::Base.establish_connection(config[db_adapter])
  load(File.dirname(__FILE__) + "/schema.rb")
  require File.dirname(__FILE__) + '/../rails/init.rb'
end

# # #
# helpers
#
def assert_not boolean, *msg
  assert !boolean, *msg
end

