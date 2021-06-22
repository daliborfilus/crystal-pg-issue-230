require "db"
require "pg"
require "log"

module Issue230
  VERSION = "0.1.0"

  module App
    extend self

    # @see <https://crystal-lang.org/docs/database/>
    # @see <https://github.com/crystal-lang/crystal-db>
    class DbHandle
      Log = ::Log.for(self)

      getter connection : DB::Database

      # connect to the database
      # @param [String] connection_string e.g. "postgres://localhost:15432/cmdb?characterEncoding=UTF-8"
      def initialize(@connection_string : String)
        @connection = DB.open(connection_string)
      end

      # destructor for db connection
      def finalize
        @connection.close
      end
    end

    def main
      ::Log.setup_from_env(default_level: :info, backend: ::Log::IOBackend.new(STDERR))

      queries = [] of String

      queries << <<-SQL
      create table if not exists test (
        name text,
        code text,
        created_at timestamp with time zone default current_timestamp
      )
      SQL

      queries << "SELECT 1"
      queries << "TRUNCATE test CASCADE"

      (1..1000).map do |i|
        queries << <<-SQL
        INSERT INTO test (code, name) VALUES ('Code #{i}', 'Name #{i}');
        SQL
      end

      connection_string = "postgres://postgres:postgres@postgres:5432/app"

      handle = DbHandle.new(connection_string)
      handle.connection.transaction do |tx|
        affected = 0
        queries.each do |query_str|
          affected += tx.connection.exec(query_str).rows_affected
        end
        Log.info { "Affected rows total: #{affected}" }
      end
    end
  end
end

Issue230::App.main
