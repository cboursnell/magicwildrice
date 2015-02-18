module MagicWildRice

  class Fastqc

    attr_accessor :read_count
    attr_reader :phred, :read_length

    def initialize
      @acgt = []
      @kmers = {}
      @read_length = []
      @qual = []
      @k = 6
      @read_count = 0
      @min = 200
      @max = 0
      @phred = -1
    end

    def run file
      @file = file
      # - per base quality (counts of each quality per base-position)
      # - per base acgt content (counts of each nucleotide per base-position)
      # - number of reads
      # - high abundance kmers (k=6)
      # - read length distribution

      handle = File.open(file)
      name = handle.readline
      seq = handle.readline
      plus = handle.readline
      qual = handle.readline
      while name
        @read_count += 1
        acgt_content(seq)
        kmer_count(seq)
        length_hist(seq)
        quality(qual)
        name = handle.readline rescue nil
        seq = handle.readline rescue nil
        plus = handle.readline rescue nil
        qual = handle.readline rescue nil
      end
    end

    def acgt_content seq
      seq.chomp.each_char.with_index do |char, i|
        @acgt[i] ||= {}
        @acgt[i][char] ||= 0
        @acgt[i][char] += 1
      end
      @acgt
    end

    def kmer_count seq
      (0..(seq.length-@k)).each do |i|
        kmer = seq[i..(i+@k-1)]
        @kmers[kmer] ||= 0
        @kmers[kmer] += 1
      end
      @kmers
    end

    def length_hist seq
      l = seq.chomp.length
      @read_length[l] ||= 0
      @read_length[l] += 1
      @read_length
    end

    def quality qual
      qual.chomp.each_char.with_index do |qual, i|
        @qual[i] ||= {}
        @qual[i][qual.ord] ||= 0
        @qual[i][qual.ord] += 1
      end
      @qual
    end

    def output
      # base composition
      str = "base\ta\tc\tg\tt\tn\n"
      @acgt.each.with_index do |h, i|
        a = h["A"].nil? ? 0 : h["A"]
        c = h["C"].nil? ? 0 : h["C"]
        g = h["G"].nil? ? 0 : h["G"]
        t = h["T"].nil? ? 0 : h["T"]
        n = h["N"].nil? ? 0 : h["N"]
        str << "#{i}\t#{a}\t#{c}\t#{g}\t#{t}\t#{n}\n"
      end
      filename = File.basename(@file)
      File.open("per_base_composition.txt","wb") { |io| io.write str }

      # quality
      str = "base\tmean\n"
      @qual.each_with_index do |h, i|
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
      File.open("per_base_quality.txt","wb") { |io| io.write str }

      # quality for geom_tile
      str = "base\t"
      str << "#{(@min..@max).to_a.join("\t")}\n"
      @qual.each_with_index do |h, i|
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
      File.open("per_base_quality_tile.txt","wb") { |io| io.write str }

      # read length
      str = "length\tcount\n"
      @read_length.each_with_index do |c,i|
        if !c.nil? and c > 0
          str << "#{i}\t#{c}\n"
        end
      end
      File.open("read_length_hist.txt","wb") { |io| io.write str }

      # read count
      str = "#{@file}\t#{@read_count}"
      File.open("read_count.txt","wb") { |io| io.write str }
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