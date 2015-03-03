module MagicWildRice

  require 'fixwhich'

  class Tophat

    def initialize threads = 8
      @build = Which::which('bowtie2-build').first
      @tophat = Which::which('tophat2').first
      @cufflinks = Which::which('cufflinks').first
      @gffread = Which::which('gffread').first
      @threads = threads
    end

    def run reference, left, right
      build_index reference
      tophat left, right
      cufflinks
      return assemble reference
    end

    def build_index reference
      @output = "tophat_#{File.basename(reference, File.extname(reference))}"
      @index = File.basename(reference, File.extname(reference))
      cmd = "#{@build} #{reference} #{@index}"
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
      fasta = "#{@output}/#{@index}-transcripts.fa"
      cmd =  "#{@gffread} "
      cmd << " -w #{fasta}"
      cmd << " -g #{reference}"
      cmd << " #{@output}/transcripts.gtf"
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

