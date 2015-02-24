module MagicWildRice

  require 'fileutils'

  class MagicWildRice

    attr_reader :files

    def initialize yaml
      @data_file = File.expand_path(yaml)
    end

    def load_data
      @files = YAML.load(File.read(@data_file))
      @files.each do |info|
        info["files"].each_with_index do |file, index|
          info["files"][index] = File.expand_path(file)
        end
      end
    end

    def install_dependencies
    end

    def fastqc
      return if @files.nil? or @files.size == 0
      read_count = File.join("data", "fastqc", "read_counts.txt")
      FileUtils.mkdir_p(File.dirname(read_count))
      read_count_handle = File.open(read_count, "wb")
      @files.each do |info|
        dir = File.join("data", "fastqc", info["name"])
        FileUtils.mkdir_p(dir)
        left, right = info["files"]
        Dir.chdir(dir) do
          qc = Fastqc.new
          qc.run left, right
          read_count_handle.write "#{info["name"]}\t#{qc.output}\n"
        end
      end
    end

    # TODO move this to the plots class
    def plots
      gem_dir = Gem.loaded_specs['magic-wild-rice'].full_gem_path
      @files.each do |info|
        dir = File.expand_path(File.join("data", "fastqc", info["name"]))
        [:left, :right].each do |pair|
          dir_pair = File.join(dir, pair.to_s)
          Dir.chdir(dir) do
            plots = Plots.new dir_pair
            plots.run_r
          end
        end
        Dir.chdir(dir) do
          plots = Plots.new dir
          plots.read_count
        end
      end
    end

  end

end
