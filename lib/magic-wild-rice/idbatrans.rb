module MagicWildRice

  require 'fileutils'
  require 'fixwhich'

  class IdbaTrans

    def initialize
      @idba = Which::which('idba_tran').first
      raise "Can't find idba_tran in path" if @idba.nil?
      @fq2fa = Which::which('fq2fa').first
      raise "Can't find fq2fa in path" if @fq2fa.nil?
    end

    def run left, right, threads = 8
      @threads = threads
      reads = prepare_reads left, right
      idba = Cmd.new build_cmd(reads)
      output = "#{@output}/contig.fa"
      unless File.exist?(output)
        idba.run
      end
      return output
    end

    def build_cmd reads
      idba_cmd = "#{@idba} "
      @output = File.basename(reads, File.extname(reads))
      idba_cmd << "-o #{@output} "            # output
      idba_cmd << "-r #{reads} "              # input
      idba_cmd << "--num_threads #{@threads} " # number of threads
      idba_cmd << "--mink 21 "                # minimum k value (<=124)
      idba_cmd << "--maxk 77 "                # maximum k value (<=124)
      idba_cmd << "--step 4 "                 # increment k
      idba_cmd << "--min_count 1 "            # minimum multiplicity for filter
      idba_cmd << "--no_correct "             # do not do correction
      idba_cmd << "--max_isoforms 6 "         # maximum number of isoforms
      idba_cmd << "--similar 0.98"            # similarity for alignment
      return idba_cmd
    end

    def prepare_reads left, right
      output = File.basename("#{lcs [left, right]}.fa")
      cmd = "#{@fq2fa} --merge #{left} #{right} #{output}"
      merge = Cmd.new cmd
      merge.run
      return output
    end

    def lcs a # longest common substring
      s = a.min_by(&:size)
      lcs = catch(:hit) {
        s.size.downto(1) { |i|
          (0..(s.size - i)).each { |l|
            throw :hit, s[l, i] if a.all? { |item| item.include?(s[l, i]) }
          }
        }
      }
      lcs = "out" if lcs.length == 0
      lcs = lcs[0..lcs.length-2] if lcs[lcs.length-1]=="_"
    end

  end

end
