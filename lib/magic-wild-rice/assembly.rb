module MagicWildRice

  require 'fileutils'
  require 'bio'
  require 'preprocessor'

  class Assembly

    # do genome based and de novo assembly of crosses

    def initialize details
      @all = details
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

        desc.split("/").each do |p|
          @parents.each do |i|
            if i["desc"] =~ /#{p}/
              cat[i["desc"].tr(" ", "_").downcase] = i["genome"]["fa"]
            end
          end
        end
        cat.each do |name, fa|
          fixed_genome = "#{File.basename(name, File.extname(name))}_fixed.fa"
          fixed_genome = File.expand_path(File.join("data", "assembly",
                                                    "reference", fixed_genome))
          unless File.exist?(fixed_genome)
            # add species name to fasta file before concatenating
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
            FileUtils.mkdir_p(File.dirname(fixed_genome))
            File.open(fixed_genome, "wb") {|out| out.write output}
          end
          cat[name] = fixed_genome
        end

        cat_name = []
        cmd = "cat " + cat.keys.reduce("") do |sum, name|
          cat_name << name
          sum << " #{cat[name]} "
        end
        genome = "#{cat_name.join("-")}.fa"
        genome = File.expand_path(File.join("data", "assembly",
                                            "reference", genome))
        cmd << " > #{genome}"
        puts cmd
        path = File.expand_path(File.join("data", "assembly", "reference"))
        Dir.chdir(path) do
          catter = Cmd.new cmd
          result = catter.run genome
          info["genome"] = genome # File.expand_path(genome)
          tophat(info) # run tophat assembly
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
      @memory = 128
      #
      @all.each do |info|
        left = info["files"][0]
        right = info["files"][1]
        name = info["desc"].tr("/", "_").downcase
        puts "name  : #{name}"
        # soap = Soap.new
        path = File.join("data", "assembly", "de_novo", name)
        FileUtils.mkdir_p(path)
        Dir.chdir(path) do
          pre = Preprocessor::Preprocessor.new("preprocessing", false, @threads, @memory)
          contig_files = []

          pre.load_reads(left, right, name)
          puts "trimming..."
          pre.trimmomatic
          puts "hammering..."
          pre.hammer
          puts "norming..."
          pre.bbnorm
          left = pre.data[0][:current]
          right = pre.data[1][:current]

          contig_files << idba(name, left, right)
          contig_files << soap(name, left, right)
          contig_files << oases(name, left, right)
          contig_files << trinity(name, left, right)
          contig_files << sga(name, left, right)
          # add more assembly methods here

          # transrate all contigs individually
          scores = transrate contig_files, left, right
          # filter out contigs with 0.01 score
          contig_files = filter_contigs scores, contig_files
          # cluster all contigs
          cluster = Cluster.new
          output = cluster.run(name, contig_files, scores)
          puts "best contigs saved in #{output}\n"
        end
      end
    end

    def idba name, left, right
      idba = IdbaTrans.new @threads
      puts "idba..."
      idba_contigs = idba.run(name, left, right)
      return File.expand_path(rename_contigs(idba_contigs, "idba"))
    end

    def soap name, left, right
      soap = SoapDeNovo.new @threads
      puts "soap..."
      soap_contigs = soap.run(name, left, right)
      return File.expand_path(rename_contigs(soap_contigs, "soap"))
    end

    def oases name, left, right
      oases = Oases.new @threads
      puts "oases..."
      oases_contigs = oases.run(name, left, right)
      return File.expand_path(rename_contigs(oases_contigs, "oases"))
    end

    def trinity name, left, right
      trinity = Trinity.new @threads
      puts "trinity..."
      trinity_contigs = trinity.run(name, left, right)
      return File.expand_path(rename_contigs(trinity_contigs, "trinity"))
    end

    def sga name, left, right
      sga = Sga.new @threads
      puts "sga..."
      sga_contigs = sga.run(name, left, right)
      return File.expand_path(rename_contigs(sga_contigs, "sga"))
    end

    def filter_contigs scores, contig_files
      new_files = []
      contig_files.each do |file|
        puts "filtering on #{file}..."
        new_filename = "#{File.basename(file, File.extname(file))}_filtered.fa"
        new_filename = File.expand_path(new_filename)
        unless File.exist?(new_filename)
          str = ""
          Bio::FastaFormat.open(file).each do |entry|
            name = entry.entry_id
            if scores.key?(name)
              if scores[name] > 0.01
                str << ">#{name}\n"
                str << "#{entry.seq}\n"
              end
            else
              puts "can't find #{name} in scores hash"
            end
          end

          puts "writing new filtered fasta file #{new_filename}"
          File.open("#{new_filename}", "wb") { |out| out.write(str)}
        end
        new_files << new_filename
      end
      return new_files
    end

    def rename_contigs file, name
      output = "#{name}_contigs.fa"
      count = 0
      File.open(output, "wb") do |out|
        Bio::FastaFormat.open(file).each do |entry|
          out.write ">#{name}_contig#{count}\n"
          out.write "#{entry.seq}\n"
          count += 1
        end
      end
      return output
    end

    def transrate list, left, right
      scores = {}
      dir = "transrate"
      gem_dir = Gem.loaded_specs['transrate'].full_gem_path
      transrate = File.join(gem_dir, "bin", "transrate")
      FileUtils.mkdir_p(dir)
      Dir.chdir(dir) do
        list.each do |fasta|
          puts "transrate on #{File.basename(fasta)}..."
          cmd = "#{transrate} "
          cmd << " --assembly #{fasta}"
          cmd << " --left #{left}"
          cmd << " --right #{right}"
          cmd << " --outfile transrate"
          cmd << " --threads #{@threads}"
          outfile = "transrate_#{File.basename(fasta)}_contigs.csv"
          transrater = Cmd.new(cmd)
          unless File.exist?(outfile)
            transrater.run
            File.open("#{File.basename(fasta)}.log","wb") do |out|
              out.write transrater.stdout
            end
          end
          count = 0
          CSV.foreach(outfile, :headers => true,
                               :header_converters => :symbol,
                               :converters => :all) do |row|
            name = row[:contig_name]
            score = row[:score]
            scores[name] = score
          end
        end
      end
      return scores
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

