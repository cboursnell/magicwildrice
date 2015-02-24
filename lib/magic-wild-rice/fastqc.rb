module MagicWildRice

  class Fastqc

    attr_accessor :read_count
    attr_reader :phred, :read_length

    def initialize
      @acgt = { :left => [], :right => [] }
      @kmers = { :left => {}, :right => {} }
      @read_length = { :left => [], :right => [] }
      @qual = { :left => [], :right => [] }
      @dibase = {}
      @k = 6
      @read_count = 0
      @min = 200
      @max = 0
      @phred = -1
      @composition_file = "per_base_composition.txt"
      @quality_file = "per_base_quality.txt"
      @quality_tile_file = "per_base_quality_tile.txt"
      @read_count_file = "read_length_hist.txt"
      @read_length_file = "read_count.txt"
      @dibase_file = "dibase_bias.txt"
    end

    def run left, right
      print "analysing #{left} "
      @left = left
      @right = right
      # - per base quality (counts of each quality per base-position)
      # - per base acgt content (counts of each nucleotide per base-position)
      # - number of reads
      # - high abundance kmers (k=6)
      # - read length distribution
      return if files_exist
      left_handle = File.open(left)
      right_handle = File.open(right)
      name1 = left_handle.readline
      seq1 = left_handle.readline
      plus1 = left_handle.readline
      qual1 = left_handle.readline
      name2 = right_handle.readline
      seq2 = right_handle.readline
      plus2 = right_handle.readline
      qual2 = right_handle.readline
      while name1
        @read_count += 1
        print "." if @read_count % 1000000 == 0
        analysis(seq1, seq2, qual1, qual2)
        name1 = left_handle.readline rescue nil
        seq1 = left_handle.readline rescue nil
        plus1 = left_handle.readline rescue nil
        qual1 = left_handle.readline rescue nil
        name2 = right_handle.readline rescue nil
        seq2 = right_handle.readline rescue nil
        plus2 = right_handle.readline rescue nil
        qual2 = right_handle.readline rescue nil
      end
      puts " Done"
    end

    def analysis(seq1, seq2, qual1, qual2)
      length_hist(seq1, seq2)
      acgt_content(seq1, seq2)
      # kmer_count(seq1, seq2)
      dibase_bias(seq1, seq2)
      quality(qual1, qual2)
    end

    def files_exist
      found = true

      [:left, :right].each do |pair|
        unless File.exist?(File.join(pair.to_s, @composition_file))
          found = false
        end
        unless File.exist?(File.join(pair.to_s, @quality_file))
          found = false
        end
        unless File.exist?(File.join(pair.to_s, @quality_tile_file))
          found = false
        end
        unless File.exist?(File.join(pair.to_s, @read_length_file))
          found = false
        end
      end
      unless File.exist?(@dibase_file)
        found = false
      end
      unless File.exist?(@read_count_file)
        found = false
      end

      return found
    end

    def dibase_bias seq1, seq2
      dibase1 = seq1[0..1]
      dibase2 = seq2[0..1]
      key = "#{dibase1}:#{dibase2}"
      @dibase[key] ||= 0
      @dibase[key] += 1
    end

    def acgt_content seq1, seq2
      seq1.chomp.each_char.with_index do |char, i|
        @acgt[:left][i] ||= {}
        @acgt[:left][i][char] ||= 0
        @acgt[:left][i][char] += 1
      end
      seq2.chomp.each_char.with_index do |char, i|
        @acgt[:right][i] ||= {}
        @acgt[:right][i][char] ||= 0
        @acgt[:right][i][char] += 1
      end
      @acgt
    end

    def kmer_count seq1, seq2
      (0..(seq1.length-@k)).each do |i|
        kmer = seq1[i..(i+@k-1)]
        @kmers[:left][kmer] ||= 0
        @kmers[:left][kmer] += 1
      end
      (0..(seq2.length-@k)).each do |i|
        kmer = seq2[i..(i+@k-1)]
        @kmers[:right][kmer] ||= 0
        @kmers[:right][kmer] += 1
      end
      @kmers
    end

    def length_hist seq1, seq2
      l = seq1.chomp.length
      @read_length[:left][l] ||= 0
      @read_length[:left][l] += 1
      l = seq2.chomp.length
      @read_length[:right][l] ||= 0
      @read_length[:right][l] += 1
      @read_length
    end

    def quality qual1, qual2
      qual1.chomp.each_char.with_index do |qual, i|
        @qual[:left][i] ||= {}
        @qual[:left][i][qual.ord] ||= 0
        @qual[:left][i][qual.ord] += 1
      end
      qual2.chomp.each_char.with_index do |qual, i|
        @qual[:right][i] ||= {}
        @qual[:right][i][qual.ord] ||= 0
        @qual[:right][i][qual.ord] += 1
      end
      @qual
    end

    def output
      return 0 if files_exist

      [:left, :right].each do |pair|
        FileUtils.mkdir_p(pair.to_s)

        # base composition
        str = "base\ta\tc\tg\tt\tn\n"
        @acgt[pair].each.with_index do |h, i|
          a = h["A"].nil? ? 0 : h["A"]
          c = h["C"].nil? ? 0 : h["C"]
          g = h["G"].nil? ? 0 : h["G"]
          t = h["T"].nil? ? 0 : h["T"]
          n = h["N"].nil? ? 0 : h["N"]
          str << "#{i}\t#{a}\t#{c}\t#{g}\t#{t}\t#{n}\n"
        end
        output = File.join(pair.to_s, @composition_file)

        File.open(output,"wb") { |io| io.write str }

        # quality
        str = "base\tmean\n"
        @qual[pair].each_with_index do |h, i|
          mean = 0
          total= 0
          h.each do |qual, count|
            @min = qual if qual < @min
            @max = qual if qual > @max
            mean += qual*count.to_f
            total+= count
          end
          str << "#{i}\t#{mean/total.to_f}\n"
        end
        output = File.join(pair.to_s, @quality_file)
        File.open(output,"wb") { |io| io.write str }

        # quality for geom_tile
        str = "base\t"
        str << "#{(@min..@max).to_a.join("\t")}\n"
        @qual[pair].each_with_index do |h, i|
          str << "#{i}"
          (@min..@max).to_a.each do |q|
            if h[q]
              str << "\t#{h[q]}"
            else
              str << "\t0"
            end
          end
          str << "\n"
        end
        output = File.join(pair.to_s, @quality_tile_file)
        File.open(output,"wb") { |io| io.write str }

        # read length
        str = "length\tcount\n"
        @read_length[pair].each_with_index do |c,i|
          if !c.nil? and c > 0
            str << "#{i}\t#{c}\n"
          end
        end
        output = File.join(pair.to_s, @read_length_file)
        File.open(output,"wb") { |io| io.write str }

      end

      # read count
      str = "#{@left}\t#{@read_count}\n"
      str << "#{@right}\t#{@read_count}\n"
      File.open(@read_count_file,"wb") { |io| io.write str }

      # dibase fragment bias
      str = "bases\tcount\n"
      @dibase.each do |key, count|
        str << "#{key}\t#{count}\n"
      end
      File.open(@dibase_file, "wb") { |io| io.write str}

      return @read_count
    end

    def guess_phred qual
      n = []
      qual.each_char do |qual|
        n << qual.ord
      end
      min, max = n.minmax
      @min = min if min < @min
      @max = max if max > @max
      if @read_count >= 1000
        if @max <= 105 and @min >= 66
          @phred = 64
        elsif @max <= 74 and @min >= 33
          @phred = 33
        end
      end
    end

  end

end