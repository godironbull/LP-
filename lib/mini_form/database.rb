require "sqlite3"

class Database
  def self.connection
    @connection ||= SQLite3::Database.new("mini_framework.db")
  end
end
