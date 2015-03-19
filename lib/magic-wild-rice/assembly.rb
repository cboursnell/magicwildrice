module MagicWildRice

  require 'fileutils'
  require 'bio'
  require 'preprocessor'

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
      @threads = threads
      reference_based
      de_novo
    end

    def run_de_novo threads
      @threads = threads
      de_novo
    end

    def run_reference threads
      @threads = threads
      reference
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
              cat[i["desc"].tr(" ", "_").downcase] = i["genome"]["fa"]
            end
          end
        end
        cat.each do |name, fa|
          fixed_genome = "#{File.basename(name, File.extname(name))}_fixed.fa"
          fixed_genome = File.expand_path(File.join("data", "assembly", fixed_genome))
          unless File.exist?(fixed_genome)
            puts fixed_genome
            path = File.expand_path(File.join("data", "genomes", name, fa))
            output = ""
            fasta = Bio::FastaFormat.open(path)
            fasta.each do |entry|
              contig = entry.entry_id
              contig = "#{name}_#{contig}"
              output << ">#{contig}\n"
              output << "#{entry.seq}\n"
            end
            File.open(fixed_genome, "wb") {|out| out.write output}
          end
          cat[name] = fixed_genome
        end
        # add species name to fasta file before concatenating

        cat_name = []
        cmd = "cat " + cat.keys.reduce("") do |sum, name|
          cat_name << name
          path = cat[name]
          sum << " #{path} "
        end
        genome = "#{cat_name.join("-")}.fa"
        genome = File.expand_path(File.join("data", "assembly", genome))
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
        assembler = Tophat.new @threads
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
      @memory = 20
      #
      @crosses.each do |info|
        left = info["files"][0]
        right = info["files"][1]
        name = info["desc"].tr("/", "_").downcase
        puts "left  : #{left}"
        puts "right : #{right}"
        puts "name  : #{name}"
        # soap = Soap.new
        path = File.join("data", "assembly", "de_novo")
        FileUtils.mkdir_p(path)
        Dir.chdir(path) do
          pre = Preprocessor::Preprocessor.new(name, false, @threads, @memory)
          pre.load_reads(left, right, name)
          pre.trimmomatic
          pre.hammer
          left = pre.data[0][:current]
          right = pre.data[1][:current]
          idba = IdbaTrans.new @threads
          contigs = idba.run left, right
          info["idba"] = File.expand_path(contigs)
        end
      end
      p @crosses
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

