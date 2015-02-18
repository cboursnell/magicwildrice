module MagicWildRice

  require 'fileutils'

  class MagicWildRice

    def initialize
      @files = []
      Dir.chdir("data") do
        Dir["*.fq"].each do |file|
          @files << File.expand_path(file)
        end
      end
      p @files
    end

    def install_dependencies
    end

    def fastqc
      Dir.chdir("data") do
        @files.each do |file|
          dir = "fastqc/#{File.basename(file)}"
          FileUtils.mkdir_p(dir) if !Dir.exist?(dir)
          Dir.chdir(dir) do
            qc = Fastqc.new
            qc.run file
            qc.output
          end
        end
      end
    end

    # TODO move this to the plots class
    def plots
      gem_dir = Gem.loaded_specs['magic-wild-rice'].full_gem_path
      Dir.chdir("data") do
        @files.each do |file|
          dir = "fastqc/#{File.basename(file)}"
          dir = File.expand_path(dir)
          Dir.chdir(dir) do
            plots = Plots.new dir
            plots.run_r
          end
        end
      end
    end

  end

end