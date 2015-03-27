module MagicWildRice

  require 'fixwhich'

  class IdbaTrans

    def initialize threads=8
      @threads = threads
      @idba = Which::which('idba_tran').first
      raise "Can't find idba_tran in path" if @idba.nil?
      @fq2fa = Which::which('fq2fa').first
      raise "Can't find fq2fa in path" if @fq2fa.nil?
    end

    def run left, right
      reads = prepare_reads left, right
      @output = File.basename(reads, File.extname(reads))
      idba = Cmd.new build_cmd(reads)
      output = File.expand_path("#{@output}/contig.fa")
      unless File.exist?(output)
        idba.run
        unless idba.status.success?
          puts "Something went wrong with idba"
          puts idba.stderr
          puts idba.stdout
        end
      end
      return output
    end

    def build_cmd reads
      idba_cmd = "#{@idba} "
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
      unless File.exist?(output)
        cmd = "#{@fq2fa} --merge #{left} #{right} #{output}"
        merge = Cmd.new cmd
        merge.run
      end
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
      if lcs[lcs.length-1]=~/[\_\-]/
        lcs = lcs[0..lcs.length-2]
      end
      return lcs
    end

  end

end
