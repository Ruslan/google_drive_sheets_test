# https://developers.google.com/sheets/api/quickstart/python Нажать Enable the Google Sheets API и получить credentials.json, сохранить в credentials_sheets.json
# https://developers.google.com/drive/api/v3/quickstart/python Нажать Enable the Google Sheets API и получить credentials.json, сохранить в credentials_drive.json

require "google/apis/sheets_v4"
require 'google/apis/drive_v2'
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"

class DriveSheetReader
  OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
  APPLICATION_NAME = "Google Sheets API Ruby Quickstart".freeze

  def initialize
  end

  def list_files
    files = drive.list_files
    files.items.each do |file|
      if file.mime_type == 'application/vnd.google-apps.spreadsheet'
        puts "==== Гугл таблица в файле #{file.title} ==="
        read_sheet(file.id)
      end
    end
  end

  def read_sheet(id)
    range = "A1:B3"
    response = sheets.get_spreadsheet_values id, range
    puts "Данные из ячеек #{range} этого файла:"
    return puts "Нет данных." unless response.values&.any?
    response.values.each do |row|
      puts "#{'%20s' % row[0]}\t|\t#{row[1]}"
    end
  end

  def drive
    @drive ||= begin
      drive = Google::Apis::DriveV2::DriveService.new
      drive.authorization = authorize_drive
      drive
    end
  end

  def sheets
    @sheets ||= begin
      service = Google::Apis::SheetsV4::SheetsService.new
      service.client_options.application_name = APPLICATION_NAME
      service.authorization = authorize_sheets
      service
    end
  end

  def authorize_drive
    authorize(
      credentials_path: 'credentials_drive.json',
      token_path: 'token_drive.yaml',
      scope: 'https://www.googleapis.com/auth/drive.readonly'
    )
  end

  def authorize_sheets
    authorize(
      credentials_path: 'credentials_sheets.json',
      token_path: 'token_sheets.yaml',
      scope: Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY
    )
  end

  def authorize(credentials_path:, token_path:, scope:)
    client_id = Google::Auth::ClientId.from_file credentials_path
    token_store = Google::Auth::Stores::FileTokenStore.new file: token_path
    authorizer = Google::Auth::UserAuthorizer.new client_id, scope, token_store
    user_id = "default"
    credentials = authorizer.get_credentials user_id
    if credentials.nil?
      url = authorizer.get_authorization_url base_url: OOB_URI
      puts "Open the following URL in the browser and enter the " \
           "resulting code after authorization:\n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end
    credentials
  end
end

DriveSheetReader.new.list_files
