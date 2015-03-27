module MagicWildRice

  class Cluster

    def initialize

    end

    def run list
      cat = "cat "
      list.each do |fasta|
        cat << " #{fasta} "
      end
      cat << " > all.fa"
      puts cat
      puts "running vsearch clustering on all.fa"

    end

  end

end