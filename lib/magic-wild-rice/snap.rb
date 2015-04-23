module MagicWildRice

  class Snap

    require 'bio'

    attr_reader :index_name, :sam, :read_count

    def initialize
      which_snap = Cmd.new('which snap')
      which_snap.run
      if !which_snap.status.success?
        raise RuntimeError.new("could not find snap in the path")
      end
      @snap = which_snap.stdout.split("\n").first

      @index_built = false
      @index_name = ""
    end

    def map_reads(left, right, threads=8)
      raise RuntimeError.new("Index not built") if !@index_built

      lbase = File.basename(left.split(",").first)
      rbase = File.basename(right.split(",").first)
      index = File.basename(@index_name)
      @sam = File.expand_path("#{lbase}.#{rbase}.#{index}.sam")
      @read_count_file = "#{lbase}-#{rbase}-read_count.txt"

      unless File.exists? @sam
        snapcmd = build_paired_cmd(left, right, threads)
        runner = Cmd.new snapcmd
        puts snapcmd
        runner.run
        save_readcount runner.stdout
        unless runner.status.success?
          raise RuntimeError.new("Snap failed\n#{runner.stderr}")
        end
      else
        load_readcount left
      end
      @sam
    end

    def build_index file, threads=8, seed_size=20
      @index_name = "#{File.basename(file, File.extname(file))}_index"
      unless Dir.exists?(@index_name)
        cmd = "#{@snap} index #{file} #{@index_name}"
        cmd << " -s #{seed_size}"
        cmd << " -t#{threads}"
        cmd << " -bSpace" # contig name terminates with space char
        runner = Cmd.new cmd
        puts cmd
        runner.run
        unless runner.status.success?
          err = runner.stderr
          msg = "Failed to build Snap index\n#{runner.stderr}"
          raise RuntimeError.new(msg)
        end
      end
      @index_built = true
    end

    def build_paired_cmd l, r, threads
      cmd = "#{@snap} paired #{@index_name}"
      l.split(",").zip(r.split(",")).each do |left, right|
        cmd << " #{left} #{right}"
      end
      cmd << " -o #{@sam}"
      cmd << " -s 0 10000" # min and max distance between paired-read starts
      cmd << " -H 300000" # max seed hits to consider in paired mode
      cmd << " -h 2000" # max seed hits to consider when reverting to single
      cmd << " -d 2" # max edit distance
      cmd << " -t #{threads}"
      cmd << " -b" # bind threads to cores
      cmd << " -M"  # format cigar string
      cmd << " -D 5" # extra edit distance to search. needed for -om
      cmd << " -om 5" # Output multiple alignments. extra edit distance
      cmd << " -omax 100" # max alignments per pair/read
      cmd
    end

    def save_readcount stdout
      stdout.split("\n").each do |line|
        cols = line.split(/\s+/)
        if cols.size > 5 and cols[0]=~/[0-9\,]+/
          @read_count = cols[0].gsub(",", "").to_i / 2
          File.open("#{@read_count_file}", "wb") do |out|
            out.write("#{@read_count}\n")
          end
        end
      end
    end

    def load_readcount reads
      @read_count = 0
      if File.exist?("#{@read_count_file}")
        @read_count = File.open("#{@read_count_file}").readlines.join.to_i
      else
        reads.split(",").each do |l|
          cmd = "wc -l #{l}"
          count = Cmd.new(cmd)
          count.run
          if count.status.success?
            @read_count += count.stdout.strip.split(/\s+/).first.to_i/4
            File.open("#{@read_count_file}", "wb") do |out|
              out.write("#{@read_count}\n")
            end
          else
            logger.warn "couldn't get number of reads from #{l}"
          end
        end
      end
    end

  end # Snap

end # Transrate
