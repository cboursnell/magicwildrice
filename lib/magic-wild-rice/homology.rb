module MagicWildRice

  require 'fileutils'
  require 'crb-blast'

  class Homology

    def initialize files
      @files = files
      @url = "ftp://ftp.ensemblgenomes.org/pub/plants/release-26/fasta"
      @url << "/oryza_sativa/pep/Oryza_sativa.IRGSP-1.0.26.pep.all.fa.gz"
      @synteny_hash = {}
      @synteny_list = []
    end

    def run threads
      @threads = threads
      download # proteome
      get_transcriptomes
      crb_to_proteome
    end

    def get_transcriptomes
      @list = []
      @files.each do |info|
        name = info["desc"].gsub(/[\ \/]/, "_").downcase
        if info["genome"]
          # parent
          fasta = "#{name}-transcripts.fa"
          transcriptome = File.join("data", "synteny", name, fasta)
        else
          # cross
          fasta = "#{name}_best.fa"
          transcriptome = File.join("data", "assembly", "de_novo", name, fasta)
        end
        info["transcriptome"] = File.expand_path(transcriptome)
        @list << info
      end
    end

    def crb_to_proteome
      @files.each do |info|
        name = info["desc"].gsub(/[\ \/]/, "_").downcase
        query_file = File.expand_path(info["transcriptome"])
        target_file = File.expand_path(@proteome)
        path = File.join("data", "homology", name)
        FileUtils.mkdir_p(path)
        Dir.chdir(path) do
          puts "crb blast #{name} assembly to proteome"
          blaster = CRB_Blast::CRB_Blast.new(query_file, target_file)
          blaster.makedb
          blaster.run_blast(1e-5, @threads, true)
          blaster.load_outputs
          blaster.find_reciprocals
          blaster.find_secondaries
          blaster.reciprocals.each_pair do |query_id, hits|
            hits.each do |hit|
              from_key = "#{name}:#{hit.query}"
              to_key = "#{hit.target}"
              @synteny_hash[from_key] = to_key
              # @synteny_hash[to_key] = from_key
            end
          end
        end
      end
      path = File.join("data", "homology")
      Dir.chdir(path) do
        File.open("results.crb", "wb") do |out|
          @synteny_hash.each do |contig, gene|
            out.write "#{contig}\t#{gene}\n"
          end
        end
      end
    end

    # def crb
    #   list.each_with_index do |a, i|
    #     list.each_with_index do |b, j|
    #       if i!=j
    #         query_file = a["transcriptome"]
    #         target_file = b["transcriptome"]
    #         query_name = a["desc"].gsub(/[\ \/]/, "_").downcase
    #         target_name = b["desc"].gsub(/[\ \/]/, "_").downcase
    #         path = "#{query_name}-v-#{target_name}"
    #         path = File.join("data", "homology", path)
    #         FileUtils.mkdir_p(path)
    #         Dir.chdir(path) do
    #           puts "creating new crb-blast object with "
    #           puts "  query_file: #{query_file}"
    #           puts "  targetfile: #{target_file}"
    #           blaster = CRB_Blast::CRB_Blast.new(query_file, target_file)
    #           blaster.makedb
    #           blaster.run(1e-5, @threads, true)
    #           blaster.load_outputs
    #           blaster.find_reciprocals
    #           blaster.find_secondaries
    #           crb = "#{query_name}-#{target_name}.crb"
    #           File.open(crb, "wb") do |out|
    #             blaster.reciprocals.each_pair do |query_id, hits|
    #               hits.each do |hit|
    #                 out.write "#{hit}\n"
    #                 @synteny_list << { :query_species => query_name,
    #                                    :target_species => target_name,
    #                                    :query => hit.query,
    #                                    :target => hit.target }
    #                 from_key = "#{query_name}:#{hit.query}"
    #                 to_key = "#{target_name}:#{hit.target}"
    #                 @synteny_hash[from_key] = to_key
    #                 @synteny_hash[to_key] = from_key
    #               end
    #             end
    #           end
    #         end
    #       end
    #     end
    #   end
    # end

    def download
      # download reference proteome
      path = File.join("data", "homology")
      FileUtils.mkdir_p(path)
      Dir.chdir(path) do |dir|
        dl = Downloader.new @url
        unless dl.run
          raise RuntimeError.new "Something went wrong downloading proteome"
        end
        @proteome = File.join(path, File.basename(dl.file))
      end
    end

	end
end
