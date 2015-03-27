module MagicWildRice

  require 'fixwhich'

  class Cluster

    def initialize
      @vsearch = Which::which('vsearch').first
    end

    def run name, list
      output_name = "#{name}-all.fa"
      cat = "cat "
      list.each do |fasta|
        cat << " #{fasta} "
      end
      cat << " > #{output_name}"
      puts cat
      catter = Cmd.new cat
      catter.run
      puts "running vsearch clustering on #{output_name}"
      cluster_output = "#{name}-clusters.txt"
      vsearch = "#{@vsearch}"
      vsearch << " --cluster_fast #{output_name}"
      vsearch << " --id 0.9"
      vsearch << " --strand both"
      vsearch << " --uc #{cluster_output}"
      puts vsearch
      cluster = Cmd.new vsearch
      cluster.run
      return cluster_output
    end

  end

end