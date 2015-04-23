module MagicWildRice

  require 'fileutils'
  require 'bio'

  class SNP

    def initialize files
      @files = files
      @genome = File.join("data", "genomes", "oryza_sativa")
      @genome = File.join(@genome, "Oryza_sativa.IRGSP-1.0.25.dna_sm.genome.fa")
    end

    def run threads
      # for all the sequences from a single parent
      # align the reads to sativa
      # and do snp calling with
      seed_size = 20
      @files.each do |info|
        desc = info["desc"]
        unless desc =~ /\//
          path = File.join("data", "snp", desc.downcase)
          FileUtils.mkdir_p path
          Dir.chdir(path) do
            # align reads against @genome with snap
            left  = info["files"][0]
            right = info["files"][1]
            snap = Snap.new
            snap.build_index @genome, threads, seed_size
            snap.map_reads left, right, threads
          end
        end
      end
    end


  end
end