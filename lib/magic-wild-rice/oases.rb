module MagicWildRice

  require 'fixwhich'

  class Oases

    def initialize threads=8
      @threads = threads
      @kmer_size = 31
      @velvetg = Which::which('velvetg').first
      @velveth = Which::which('velveth').first
      @oases = Which::which('oases').first
      found = true
      @output = "oases"
      [@velvetg, @velveth, @oases].each do |bin|
        if bin.nil?
          puts "Can't find #{bin} in path"
          found = false
        end
      end
      abort unless found
    end

    def run name, left, right
      create_hash(name, left, right) # velveth
      create_graph # velvetg
      return oases    # oases
    end

    def create_hash(output, left, right)
      cmd = "#{@velveth}"
      cmd << " #{@output}"
      cmd << " #{@kmer_size}"
      cmd << " -fastq -separate -shortPaired" # read description
      cmd << " #{left}"
      cmd << " #{right}"
      hash = Cmd.new cmd
      hash.run
      unless hash.status.success?
        msg = "Something went wrong with velveth"
        msg << "#{hash.stdout}\n"
        msg << "#{hash.stderr}\n"
      end
    end

    def create_graph output
      cmd = "#{@velvetg}"
      cmd << " #{@output}"
      cmd << " -cov_cutoff auto "
      cmd << " -ins_length 150"
      cmd << " -read_trkg yes"
      cmd << " -min_contig_lgth 100"
      cmd << " -exp_cov auto"
      graph = Cmd.new cmd
      graph.run
      unless graph.status.success?
        msg = "Something went wrong with velvetg"
        msg << "#{graph.stdout}\n"
        msg << "#{graph.stderr}\n"
      end
    end

    def oases output
      cmd = "#{@oases}"
      cmd << " #{@output}"
      assemble = Cmd.new cmd
      assemble.run
      unless assemble.status.success?
        msg = "Something went wrong with velvetg"
        msg << "#{assemble.stdout}\n"
        msg << "#{assemble.stderr}\n"
      end
      return File.join("#{@output}", "transcripts.fa")
    end

  end

end