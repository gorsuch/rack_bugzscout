require 'rubygems'
require 'bugzscout' 
 
module Rack
  # Catches all exceptions raised from the app it wraps and
  # sends a useful email with the exception, stacktrace, and
  # contents of the environment.
 
  class BugzScout
    attr_reader :fogbugz_url, :fogbugz_user, :fogbugz_project, :fogbugz_area
 
    def initialize(app,fogbugz_url,fogbugz_user,fogbugz_project='inbox',fogbugz_area='undecided')
      @app = app
      @fogbugz_url = fogbugz_url
      @fogbugz_user = fogbugz_user
      @fogbugz_project = fogbugz_project
      @fogbugz_area = fogbugz_area
    end
 
    def call(env)
      status, headers, body =
        begin
          @app.call(env)
        rescue => boom
          # TODO don't allow exceptions from send_notification to
          # propogate
          send_notification boom, env
          raise
        end
      send_notification env['rack.exception'], env if env['rack.exception']
      [status, headers, body]
    end
  
  private
    def send_notification(exception, env)
      puts "sending notification!!!!!"
      if %w(staging production).include?(ENV['RACK_ENV'])
        FogBugz::BugzScout.submit(@fogbugz_url) do |scout|
          scout.user = @fogbugz_user
          scout.project = @fogbugz_project
          scout.area = @fogbugz_area
          scout.title = exception.class.name
          scout.body = exception.message
        end
        env['bugzscout.submitted'] = true
      end
    end
  end
end