module MagicWildRice

  require 'fileutils'
  require 'bio'
  require 'preprocessor'

  class Assembly

    # do genome based and de novo assembly of crosses

    def initialize details
      @cutoff = 0.1
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
              name = i["desc"].gsub(/[\/\ ]/, "_").downcase
              cat[name] = i["genome"]["fa"]
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
      name = info["desc"].gsub(/[\/\ ]/, "_").downcase
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
      @crosses.each do |info|
        left = info["files"][0]
        right = info["files"][1]
        name = info["desc"].gsub(/[\/\ ]/, "_").downcase
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
          # run assembly with just normalised reads
          left = pre.data[0][:current]
          right = pre.data[1][:current]

          contig_files << idba(name, left, right)
          contig_files << soap(name, left, right)
          contig_files << oases(name, left, right)
          contig_files << trinity(name, left, right)
          contig_files << sga(name, left, right)

          # run transrate with all reads
          left = pre.data[0][:prenorm]
          right = pre.data[1][:prenorm]
          # transrate all contigs individually
          scores = transrate contig_files, left, right
          p = Plots.new File.join(path, "transrate")
          p.transrate_scores
          # filter out contigs with score < cutoff
          contig_files = filter_contigs scores, contig_files
          # cluster all contigs
          cluster = Cluster.new
          output = cluster.run(name, contig_files, scores)
          puts "best contigs saved in #{output}\n"
          info["transcriptome"] = File.expand_path(output)
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
        puts "filtering on #{File.basename(file)}..."
        new_filename = "#{File.basename(file, File.extname(file))}_filtered.fa"
        new_filename = File.expand_path(new_filename)
        unless File.exist?(new_filename)
          str = ""
          Bio::FastaFormat.open(file).each do |entry|
            name = entry.entry_id
            if scores.key?(name)
              if scores[name] > @cutoff
                str << ">#{name}\n"
                str << "#{entry.seq}\n"
              end
            else
              puts "can't find #{name} in scores hash"
            end
          end
          File.open("#{new_filename}", "wb") { |out| out.write(str)}
        end
        new_files << new_filename
      end
      return new_files
    end

    def rename_contigs file, name
      output = "#{name}_contigs.fa"
      unless File.exist?(output)
        count = 0
        File.open(output, "wb") do |out|
          Bio::FastaFormat.open(file).each do |entry|
            out.write ">#{name}_contig#{count}\n"
            out.write "#{entry.seq}\n"
            count += 1
          end
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
          name = File.basename(fasta, File.extname(fasta))
          FileUtils.mkdir_p(name)
          Dir.chdir(name) do
            puts "transrate on #{File.basename(fasta)}..."
            cmd = "#{transrate} "
            cmd << " --assembly #{fasta}"
            cmd << " --left #{left}"
            cmd << " --right #{right}"
            cmd << " --outfile transrate"
            cmd << " --threads #{@threads}"
            cmd << " --loglevel debug"
            outfile = "transrate_#{File.basename(fasta)}_contigs.csv"
            # puts cmd
            transrater = Cmd.new(cmd)
            out = File.expand_path(outfile)
            unless File.exist?(out)
              # puts "transrate output #{out} doesn't exist. Running transrate"
              transrater.run
              File.open("#{File.basename(fasta)}.log","wb") do |out|
                out.write transrater.stdout
              end
            end
            count = 0
            puts "  parsing #{outfile}"
            CSV.foreach(outfile, :headers => true,
                                 :header_converters => :symbol,
                                 :converters => :all) do |row|
              name = row[:contig_name]
              score = row[:score]
              scores[name] = score
            end
          end
        end
      end
      return scores
    end

    def find_homologs
      # check synteny output to see if parents have been assembled using tophat
      list = []
      @parents.each do |parent|
        name = parent["desc"].gsub(/[\ \/]/, "_").downcase
        fasta = "#{name}-transcripts.fa"
        transcriptome = File.join("data", "synteny", name, fasta)
        parent["transcriptome"] = File.expand_path(transcriptome)
        puts transcriptome
        list << parent
      end
      @crosses.each do |cross|
        name = cross["desc"].gsub(/[\ \/]/, "_").downcase
        fasta = "#{name}_best.fa"
        transcriptome = File.join("data", "assembly", "de_novo", name, fasta)
        cross["transcriptome"] = File.expand_path(transcriptome)
        puts transcriptome
        list << cross
      end
      # do all vs all crb-blast
      @synteny_hash = {}
      @synteny_list = []
      list.each_with_index do |a, i|
        list.each_with_index do |b, j|
          if i!=j
            query_file = a["transcriptome"]
            target_file = b["transcriptome"]
            query_name = a["desc"].gsub(/[\ \/]/, "_").downcase
            target_name = b["desc"].gsub(/[\ \/]/, "_").downcase
            path = "#{query_name}-v-#{target_name}"
            FileUtils.mkdir_p(path)
            Dir.chdir(path) do
              puts "creating new crb-blast object with "
              puts "  query_file: #{query_file}"
              puts "  targetfile: #{target_file}"
              puts "___"
              blaster = CRB_Blast::CRB_Blast.new(query_file, target_file)
              blaster.makedb
              blaster.run(1e-5, @threads, true)
              blaster.load_outputs
              blaster.find_reciprocals
              blaster.find_secondaries
              crb = "#{query_name}-#{target_name}.crb"
              File.open(crb, "wb") do |out|
                blaster.reciprocals.each_pair do |query_id, hits|
                  hits.each do |hit|
                    out.write "#{hit}\n"
                    @synteny_list << { :query_species => query_name,
                                       :target_species => target_name,
                                       :query => hit.query,
                                       :target => hit.target }
                    from_key = "#{query_name}:#{hit.query}"
                    to_key = "#{target_name}:#{hit.target}"
                    @synteny_hash[from_key] = to_key
                    @synteny_hash[to_key] = from_key
                  end
                end
              end
            end
          end
        end
      end
    end

    def download info
      # download genomes
      name = info["desc"].gsub(/[\/\ ]/, "_").downcase
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

