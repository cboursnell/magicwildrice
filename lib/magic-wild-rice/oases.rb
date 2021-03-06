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
      {"velvetg" => @velvetg,
       "velveth" => @velveth,
       "oases" => @oases}.each do |name, bin|
        if bin.nil?
          puts "Can't find #{name} in path"
          found = false
        end
      end
      abort unless found
    end

    def run name, left, right
      output = File.join("#{@output}", "transcripts.fa")
      unless File.exist?(output)
        create_hash(left, right) # velveth
        create_graph             # velvetg
        oases                    # oases
      end
      return output
    end

    def create_hash(left, right)
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

    def create_graph
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

    def oases
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