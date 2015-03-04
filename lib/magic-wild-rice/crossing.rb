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
      # map reads from 4way to each parent
      map
      #
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
            sam = mapper.map_reads left, right
            puts sam
          end
        end
      end
    end

    def scan
      # go through each sam file individually and find the read pairs that
      # only mapped to one genome and also have a mapq score above X
      @crosses.each do |cross|
        @parents.each do |parent|
          path = File.expand_path(File.join("data", "crossing",
                                                         "#{parent["name"]}"))
          Dir.chdir(path) do
            puts "analysing sam file in #{path}"
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
