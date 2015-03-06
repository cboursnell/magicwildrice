module MagicWildRice

  require 'fileutils'

  class Crossing

    def initialize details
      @crosses = []
      @parents = []
      @unique = {}
      @maximums = {}
      details.collect do |info|
        if info["name"].length == 4
          @crosses << info
        end
        if info["genome"]
          download info
          @parents << info
        end
      end
    end

    def run threads
      # map reads from 4way to each parent
      map
      puts "scanning"
      scan
      puts "selecting"
      select_unique
      #
    end

    def map
      # map reads from the crosses to the genomes of the parents
      mapper = Snap.new
      @crosses.each do |cross|
        @parents.each do |parent|
          path = File.expand_path(File.join("data", "crossing",
                                                         "#{parent["name"]}"))
          name = parent["desc"].tr(" ", "_").downcase
          reference = File.expand_path(File.join("data", "genomes",
                                                  name, parent["genome"]["fa"]))
          FileUtils.mkdir_p(path)
          left =  File.expand_path(parent["files"][0])
          right = File.expand_path(parent["files"][1])
          Dir.chdir(path) do
            mapper.build_index reference
            sam = mapper.map_reads left, right
            parent["sam"] = sam
          end
        end
      end
    end

    def scan
      # go through each sam file individually and find the read pairs that
      # only mapped to one genome and also have a mapq score above X
      @crosses.each do |cross|
        @parents.each do |parent|
          path = File.expand_path(File.join("data", "crossing",
                                                         "#{parent["name"]}"))
          Dir.chdir(path) do
            puts "#{parent["name"]}"
            analyse(parent["sam"], parent["name"])
          end
        end
      end
    end

    def analyse sam, name
      count = 0
      unless File.exist?("#{name}_output.txt")
        File.open(sam).each_line do |line|
          count += 1
          print "." if count % 1_000_000 == 0
          unless line.start_with?("@")
            cols = line.split("\t")
            readname = cols[0]
            flag = cols[1].to_i
            unless read_unmapped?(flag)
              chrom = cols[2]
              position = cols[3].to_i
              mapq = cols[4].to_i
              if mapq > 69
                @unique[readname] ||= {}
                pair = first_in_pair?(flag) ? :left : :right
                @unique[readname][pair] = { name => {
                                            :chrom => chrom,
                                            :position => position}
                                          }
                @maximums[name] ||= {}
                if @maximums[name][chrom] and @maximums[name][chrom] < position
                  @maximums[name][chrom] = position
                else
                  @maximums[name][chrom] = position
                end
              end
            end
          end
        end
      end
      puts " Done"
    end

    def select_unique
      buckets = {}
      @unique.each do |readname, hash|
        hash.each do |pair, info|
          if info.size == 1
            info.each do |name, pos|
              if @maximums[name]
                if @maximums[name][pos[:chrom]] > 1_000_000
                  buckets[name] ||= {}
                  chrom = pos[:chrom]
                  buckets[name][chrom] ||= {}
                  bucket = (pos[:position] / 10_000).to_i
                  buckets[name][chrom][bucket] ||= 0
                  buckets[name][chrom][bucket] += 1
                end
              end
            end
          end
        end
      end
      buckets.each do |name, info|
        File.open("#{name}_output.txt","wb") do |out|
          info.each do |chrom, bucket|
            bucket.each do |n, count|
              out.write "#{chrom}\t#{n}\t#{count}\n"
            end
          end
        end
      end
    end

    def first_in_pair? flag
      flag & 0x40 != 0
    end

    def second_in_pair? flag
      flag & 0x80 !=0
    end

    def read_unmapped? flag
      flag & 0x4 != 0
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

  end

end
