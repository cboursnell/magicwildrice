module MagicWildRice

  require 'fileutils'
  require 'fixwhich'

  class Sga

    def initialize threads=8
      @threads = threads
      @sga = Which::which('sga').first
      # raise "Can't find sga in path" if @sga.nil?
      @output = "sga"
    end

    def run name, left, right
      FileUtils.mkdir_p(@output)
      contigs = File.join(@output, "#{name}.assemble-contigs.fa")
      unless File.exist?(contigs)
        Dir.chdir(@output) do
          preprocess name, left, right
          index1 name, left, right
          filter name, left, right
          fmmerge name, left, right
          index2 name, left, right
          overlap name, left, right
          assemble name, left, right
        end
      end
      return contigs
    end

    def preprocess name, left, right
      phred = guess_phred left
      cmd = "#{@sga} preprocess"
      cmd << " --pe-mode 1"
      cmd << " -o #{name}.fastq"
      cmd << " --permute-ambiguous"
      if phred == 64
        cmd << " --phred64"
      end
      cmd << " #{left}"
      cmd << " #{right}"
      prep = Cmd.new cmd
      prep.run
      return "#{name}.fastq"
    end

    def index1 name, left, right
      cmd = "#{@sga} index"
      cmd << " -a ropebwt"
      cmd << " -t #{@threads}"
      cmd << " -p #{name}"
      cmd << " #{name}.fastq"
      index = Cmd.new cmd
      index.run
      return "#{name}.bwt"
    end

    def filter name, left, right
      output = "#{name}.filter.pass.fa"
      cmd = "#{@sga} filter"
      cmd << " -t #{@threads}"
      cmd << " -p #{name}"
      cmd << " -o #{output}"
      cmd << " --kmer-threshold 3"
      cmd << " --kmer-size 27"
      cmd << " --homopolymer-check"
      cmd << " --low-complexity-check"
      cmd << " #{name}.fastq"
      filter = Cmd.new cmd
      filter.run
      return output
    end

    def fmmerge name, left, right
      output = "#{name}.merged.fa"
      cmd = "#{@sga} fm-merge "
      # cmd << " --min-overlap #{opts.merge_overlap} " if opts.merge_overlap
      cmd << " --threads #{@threads}"
      cmd << " --prefix #{name}.filter.pass"
      cmd << " --outfile #{output}"
      cmd << "#{name}.filter.pass.fa"
      merge = Cmd.new cmd
      merge.run
      return output
    end

    def index2 name, left, right
      cmd = "#{@sga} index"
      cmd << " -a ropebwt"
      cmd << " -t #{@threads}"
      cmd << " -p #{name}.merged"
      cmd << " #{name}.merged.fa"
      index = Cmd.new cmd
      index.run
      return "#{name}.filter.pass.bwt"
    end

    def overlap name, left, right
      cmd = "#{@sga} overlap"
      cmd << " --threads #{@threads}"
      cmd << " #{name}.merged.fa"
      over = Cmd.new cmd
      over.run
      return "something"
    end

    def assemble name, left, right
      cmd = "#{@sga} assemble"
      cmd << " -o #{name}.assemble"
      cmd << " #{name}.merged.asqg.gz"
      a = Cmd.new cmd
      a.run
      return "#{name}.assemble-contigs.fa"
    end

    def guess_phred left
      count = 0
      n = {}
      fastq = File.open(left)
      while count < 4000
        line = fastq.readline rescue ""
        if count%4==3
          line.chomp.each_char do |qual|
            n[qual.ord] ||= 0
            n[qual.ord] += 1
          end
        end
        count+=1
      end
      fastq.close
      min, max = n.keys.minmax
      phred = -1
      if max <= 105 and min >= 64
        phred = 64
      elsif max <= 74 and min >= 33
        phred = 33
      end
      return phred
    end

  end

end