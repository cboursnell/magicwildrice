module MagicWildRice

  require 'fixwhich'

  class Cluster

    def initialize
      @vsearch = Which::which('vsearch').first

    end

    def run name, list, scores
      catted_fasta = "#{name}-all.fa"
      cat = "cat "
      list.each do |fasta|
        cat << " #{fasta} "
      end
      cat << " > #{catted_fasta}"
      catter = Cmd.new cat
      catter.run catted_fasta
      puts "vsearch..."
      cluster_output = "#{name}-clusters.txt"
      vsearch = "#{@vsearch}"
      vsearch << " --cluster_fast #{catted_fasta}"
      vsearch << " --id 0.94"
      vsearch << " --strand both"
      vsearch << " --uc #{cluster_output}"
      cluster = Cmd.new vsearch
      cluster.run cluster_output
      @output = "#{name}_best.fa"
      unless File.exist?(@output)
        parse_output name, cluster_output, catted_fasta, scores
      end
      return @output
    end

    def parse_output name, cluster_output, fasta, scores
      puts "  parsing vsearch output..."
      sequences = {}
      clusters = {}
      Bio::FastaFormat.open(fasta).each do |entry|
        sequences[entry.entry_id] = entry.seq
      end
      puts "  parsing clustering output..."
      File.open(cluster_output).each_line do |line|
        if line.start_with?("S") or line.start_with?("H")
          cols = line.chomp.split("\t")
          cluster = cols[1].to_i
          contig_name = cols[8]
          clusters[cluster] ||= []
          clusters[cluster] << contig_name
        end
      end
      puts "  writing output..."
      File.open(@output, "wb") do |out|
        clusters.each do |cluster_id, list|
          best_score = 0
          best_contig = ""
          list.each do |contig_name|
            if scores[contig_name] > best_score
              best_score = scores[contig_name]
              best_contig = contig_name
            end
          end
          out.write ">#{best_contig}\n"
          unless sequences.key?(best_contig)
            abort "can't find #{best_contig} in hash"
          end
          seq = sequences[best_contig]
          out.write "#{seq}\n"
        end
      end

    end

  end

end