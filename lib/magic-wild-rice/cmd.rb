require 'open3'

module MagicWildRice

  class Cmd

    attr_accessor :cmd, :stdout, :stderr, :status

    def initialize cmd
      @cmd = cmd
    end

    def run file=nil
      unless file.nil?
        puts "tesing existence of #{file}"
        return true if File.exist?(file)
      end
      @stdout, @stderr, @status = Open3.capture3 @cmd
      return false
    end

    def to_s
      @cmd
    end

  end

end
