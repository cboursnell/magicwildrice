module MagicWildRice

  require 'fileutils'

  class Crossing

    def initialize details
      @crosses = []
      @parents = []
      details.collect do |info|
        if info["name"].length == 4
          @crosses << info
        end
        if info["genome"]
          download info
          @parents << info
        end
      end
    end

    def run

    end

    def map
      # map reads from the crosses to the genomes of the parents
      mapper = Snap.new
      @crosses.each do |cross|
        @parents.each do |parent|
          path = File.expand_path(File.join("data", "crossing",
                                                         "#{parent["name"]}"))
          name = parent["desc"].tr(" ", "_").downcase
          reference = File.expand_path(File.join("data", "genomes",
                                                  name, parent["genome"]["fa"]))
          FileUtils.mkdir_p(path)
          left =  File.expand_path(parent["files"][0])
          right = File.expand_path(parent["files"][1])
          Dir.chdir(path) do
            mapper.build_index reference
            mapper.map_reads left, right
          end
        end
      end
    end

    def download info
      # download genomes
      name = info["desc"].tr(" ", "_").downcase
      path = File.join("data", "genomes", name)
      FileUtils.mkdir_p(path)
      Dir.chdir(path) do |dir|
        url = info["genome"]["url"]
        dl = Downloader.new url
        unless dl.run
          raise RuntimeError.new "Something went wrong downloading #{name}"
        end
      end
    end

  end

end
