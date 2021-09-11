# ruby today-script/today.rb
# List yesterday and today's gcal events

require 'rubygems'
require 'pp'
require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'date'
require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
APPLICATION_NAME = 'Google Calendar API'.freeze
CREDENTIALS_PATH = 'today-script/credentials.json'.freeze
# The file token.yaml stores the user's access and refresh tokens, and is
# created automatically when the authorization flow completes for the first
# time.
TOKEN_PATH = 'today-script/token.yaml'.freeze
SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
def authorize
  client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
  user_id = 'default'
  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    url = authorizer.get_authorization_url(base_url: OOB_URI)
    puts 'Open the following URL in the browser and enter the ' \
         'resulting code after authorization:\n' + url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI
    )
  end
  credentials
end

# Initialize the Google Calendar API
gcal = Google::Apis::CalendarV3::CalendarService.new
gcal.client_options.application_name = APPLICATION_NAME
gcal.authorization = authorize

# Fetch the next 30 events for the user
calendar_id = 'primary'
file_name = 'today-script/today.md'

events = gcal.list_events(calendar_id,
                               max_results: 30,
                               single_events: true,
                               order_by: 'startTime',
                               time_min: (Date.today - 1).rfc3339,
                               time_max: (Date.today + 1).rfc3339)

# Create dynamic headers in the file                               
def header(text, location)
  location.puts text
  location.puts '-' * text.size
end

# List out desired event info under proper headings
if !events.items.empty?
  File.open(file_name, 'w') do |file|
    file = File.new(file_name, 'w')

    events.items.each do |event|
      if event.start.date_time === (Date.today - 1)
        if ($needs_header_yday ||= [true]).shift
          header("Yesterday", file)
        end
        file.puts "- (x) #{event.summary}"
      elsif event.start.date_time === Date.today
        start = event.start.date_time.strftime('%l:%M%p')
        if ($needs_header_tday ||= [true]).shift 
          file.puts # blank line
          header("Today", file)
        end
        file.puts "- ( ) #{event.summary} -- #{start}"
      end
    end
  end
end

# At various times, I've also used the jira-ruby gem
# to pull my current work into this file
# https://github.com/sumoheavy/jira-ruby/

system('code', file_name)
