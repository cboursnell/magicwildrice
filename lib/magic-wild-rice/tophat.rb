module MagicWildRice

  require 'fixwhich'

  class Tophat

    attr_accessor :threads

    def initialize threads = 8
      @build = Which::which('bowtie2-build').first
      @tophat = Which::which('tophat2').first
      @cufflinks = Which::which('cufflinks').first
      @gffread = Which::which('gffread').first
      @threads = threads
    end

    def run info, left, right
      @name = info["desc"].tr(" ", "_").downcase
      gem_dir = Gem.loaded_specs['magic-wild-rice'].full_gem_path
      path = File.join(gem_dir, "data", "genomes", @name, info["genome"]["fa"])
      reference = File.expand_path(path)
      build_index reference
      tophat left, right
      cufflinks
      return assemble(reference)
    end

    def build_index reference
      @output = @name
      # @index = File.basename(reference, File.extname(reference))
      @index = @name
      cmd = "#{@build} #{reference} #{@index}"
      puts "building #{@index}"
      puts cmd
      indexer = Cmd.new cmd
      unless File.exist?("#{@index}.1.bt2")
        indexer.run
        unless indexer.status.success?
          puts indexer.stdout
          puts indexer.stderr
          abort "Something went wrong with building the bowtie2 index"
        end
      end
    end

    def tophat left, right
      cmd =  "#{@tophat}"
      cmd << " -o #{@output}"
      cmd << " -p #{@threads}"
      cmd << " --phred64-quals "
      cmd << " --no-convert-bam "
      cmd << " --b2-very-sensitive "
      cmd << " --keep-tmp "
      cmd << " #{@index} "
      cmd << " #{left}"
      cmd << " #{right}"
      puts "*"*12 + " TOPHAT " + "*"*12
      puts cmd
      mapper = Cmd.new cmd
      unless File.exist?("#{@output}/accepted_hits.sam")
        mapper.run
        unless mapper.status.success?
          puts mapper.stdout
          puts mapper.stderr
          abort "Something went wrong with tophat2"
        end
      end
    end

    def cufflinks
      cmd =  "#{@cufflinks}"
      cmd << " -o #{@output} "
      cmd << " -p #{@threads} "
      cmd << " #{@output}/accepted_hits.sam "
      puts "*"*12 + " CUFFLINKS " + "*"*12
      puts cmd
      annotate = Cmd.new cmd
      unless File.exist?("#{@output}/transcripts.gtf")
        annotate.run
        unless annotate.status.success?
          puts annotate.stdout
          puts annotate.stderr
          abort "Something went wrong with cufflinks"
        end
      end
    end

    def assemble reference
      fasta = "#{@output}/#{@name}-transcripts.fa"
      cmd =  "#{@gffread} "
      cmd << " -w #{fasta}"
      cmd << " -g #{reference}"
      cmd << " #{@output}/transcripts.gtf"
      puts "*"*12 + " GFFREAD " + "*"*12
      puts cmd
      assembly = Cmd.new cmd
      unless File.exist?(fasta)
        assembly.run
        unless assembly.status.success?
          puts assembly.stdout
          puts assembly.stderr
          abort "Something went wrong with gffread"
        end
      end
      return fasta
    end

  end

end

