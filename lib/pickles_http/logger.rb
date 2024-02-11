require_relative 'utils'

class PicklesHttpServer
  class PicklesLogger
    include PicklesHttpServer::Utils

    def initialize(log_path = "./log.txt")
      @log_file = File.open(log_path, 'a')
    end

    def set_log_path(new_path)
      @log_file.close if @log_file
      @log_file = File.open(new_path, 'a')
    end

    def log(message, severity = LogMode::INFO)
      severity_level = LogMode::SEVERITIES[severity.upcase] || LogMode::SEVERITIES[LogMode::INFO]
      log_entry(severity_level, message)
    end

    def close
      @log_file.close if @log_file
    end

    private

    def log_entry(level, message)
      timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
      log_entry = "[#{timestamp}] [#{level}] #{message}\n"
      puts log_entry
      @log_file.puts(log_entry)
    end
  end
end
