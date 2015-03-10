module MagicWildRice

  require 'fileutils'

  class Assembly

    # do genome based and de novo assembly of crosses

    def initialize details
      @parents = []
      @crosses = []

      details.collect do |info|
        if info["genome"]
          download info
          @parents << info
        else
          @crosses << info
        end
      end
    end

    def run threads
      reference_based
      de_novo
    end

    def reference_based
      ### genome based
      # for each cross run a tophat assembly
      # against a concatenated genome of its parents
      @crosses.each do |info|
        desc = info["desc"]
        cat = {}
        puts "cross: #{desc}"
        desc.split("/").each do |p|
          @parents.each do |i|
            if i["desc"] =~ /#{p}/
              cat[i["genome"]["fa"]] = i["desc"].tr(" ", "_").downcase
            end
          end
        end
        cat_name = []
        cmd = "cat " + cat.keys.reduce("") do |sum, k|
          name = cat[k]
          cat_name << name
          sum << "#{File.expand_path(File.join("data", "genomes", name, k))} "
        end
        genome = "#{cat_name.join("-")}.fa"
        cmd << " > #{genome}"
        puts cmd
        path = File.expand_path(File.join('data', 'assembly'))
        FileUtils.mkdir_p(path)
        Dir.chdir(path) do
          catter = Cmd.new cmd
          result = catter.run genome
          info["genome"] = File.expand_path(genome)
          p info
          puts result
          tophat info
        end
      end
    end

    def tophat info
      left = info["files"][0]
      right = info["files"][1]
      name = info["desc"].tr("/", "_").downcase
      reference = info["genome"]
      path = name
      puts "path :  #{path}"
      FileUtils.mkdir_p(path)
      Dir.chdir(path) do |dir|
        assembler = Tophat.new
        fasta = assembler.run reference, left, right
        path = File.join(path, fasta)
      end
      return path
    end

    def de_novo
      ### de novo
      # for each cross run soap, trinity, trans-idba
      # merge outputs
      # transrate and choose highest scoring contig from each 'cluster'
      # don't use transrate automatic cutoff
      #
      ###

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

