module MagicWildRice

  require 'fileutils'
  require 'crb-blast'

  class Synteny

    def initialize
      @synteny_list = []
      @synteny_hash = {}
      @annotation = {}
    end

    def run list, threads
      @threads = threads
      @assembler = Tophat.new threads
      # assemble parents using reference genome
      @assembler.threads = threads
      list.each do |info|
        download(info)
        fasta = tophat(info)
        info["transcriptome"] = fasta
        puts "loading gtf of #{info["desc"]}"
        load_gtf(info)
      end
      # do pairwise crb-blast
      (0..list.length-2).each do |i|
        (i+1..list.length-1).each do |j|
          puts "blasting #{list[i]["desc"]} and #{list[j]["desc"]}"
          crb(list[i], list[j])
        end
      end
      output = File.expand_path(File.join("data", "synteny", "synteny_data.csv"))
      File.open(output, "wb") do |io|
        @synteny_hash.each do |key, value|
          a, b = nil
          if @annotation.key?(key)
            a = @annotation[key]
          end
          if @annotation.key?(value)
            b = @annotation[value]
          end
          if a and b
            str = "#{key.split(":").first}\t#{a[:chrom]}\t#{a[:start]}\t"
            str << "#{value.split(":").first}\t#{b[:chrom]}\t#{b[:start]}\n"
            io.write str
          end
        end
      end
      plot = Plots.new File.dirname(output)
      plot.synteny_plot
    end

    def download info
      # download genomes
      name = info["desc"].tr(" ", "_").downcase
      path = File.join("data", "genomes", name)
      FileUtils.mkdir_p(path)
      Dir.chdir(path) do |dir|
        url = info["genome"]["url"]
        dl = Downloader.new url
        unless dl.run
          raise RuntimeError.new "Something went wrong downloading #{name}"
        end
      end
    end

    def tophat info
      left = info["files"][0]
      right = info["files"][1]
      name = info["desc"].tr(" ", "_").downcase
      path = File.expand_path(File.join("data", "synteny"))
      FileUtils.mkdir_p(path)

      Dir.chdir(path) do |dir|
        fasta = @assembler.run info, left, right
        path = File.join(path, fasta)
      end
      return path
    end

    def crb query, target
      path = File.expand_path(File.join("data", "synteny"))
      Dir.chdir(path) do
        query_file = query["transcriptome"]
        target_file = target["transcriptome"]
        blaster = CRB_Blast::CRB_Blast.new(query_file, target_file)
        query_name = query["desc"].tr(" ", "_").downcase
        target_name = target["desc"].tr(" ", "_").downcase
        crb = "#{query_name}-#{target_name}.crb"
        dbs = blaster.makedb
        run = blaster.run_blast(1e-5, @threads, true)
        load = blaster.load_outputs
        recips = blaster.find_reciprocals
        secondaries = blaster.find_secondaries

        File.open(crb, 'w') do |out|
          blaster.reciprocals.each_pair do |query_id, hits|
            hits.each do |hit|
              out.write "#{hit}\n"
              @synteny_list << { :query_species => query_name,
                                 :target_species => target_name,
                                 :query => hit.query,
                                 :target => hit.target }
              from_key = "#{query_name}:#{hit.query}"
              to_key = "#{target_name}:#{hit.target}"
              @synteny_hash[from_key] = to_key
              @synteny_hash[to_key] = from_key
            end
          end
        end
        # blaster.tidy_up
      end
    end

    def load_gtf info
      name = info["desc"].tr(" ", "_").downcase
      path = File.expand_path(File.join("data", "synteny"))
      genome = info["genome"]["fa"]
      genome = File.basename(genome, File.extname(genome))
      tophat_output = "#{name}/transcripts.gtf"
      tophat_output = File.join(path, tophat_output)
      maximum = {}
      puts "opening #{tophat_output}"
      File.open(tophat_output).each_line do |line|
        cols = line.chomp.split("\t")
        if cols[2] == "transcript"
          chrom = cols[0]
          start = cols[3].to_i
          stop = cols[4].to_i
          desc = cols[8]
          cols[8].split(";").each do |item|
            key, value = item.split(" ")
            if key=="transcript_id"
              desc = value.gsub("\"", "")
            end
          end
          @annotation["#{name}:#{desc}"] = { :chrom => chrom,
                                             :start => start,
                                             :stop => stop }

          maximum[chrom] ||= 0
          if maximum[chrom] < start
            maximum[chrom] = start
          end
        end
      end
      # p maximum
      # @annotation.each do |key, value|
      #   if rand < 0.0001
      #     puts "#{key}\t#{value}"
      #   end
      # end
      maximum.each do |key, value|
        if value < 1_000_000
          # puts "deleting all genes from #{key} because length==#{value}"
          list = @annotation.keys
          list.each do |namedesc|
            if @annotation[namedesc][:chrom]==key
              @annotation.delete(namedesc)
              # puts "deleting #{namedesc} from @annotation"
            end
          end
        end
      end
    end

  end

end
