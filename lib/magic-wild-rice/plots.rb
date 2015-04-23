module MagicWildRice

  class Plots

    def initialize dir
      gem_dir = Gem.loaded_specs['magic-wild-rice'].full_gem_path
      @rpath = File.join(gem_dir, "lib", "R")
      @dir = dir
    end

    def fastqc
      per_base_count
      per_base_quality_tile
      read_mean_quality
    end

    def per_base_count
      script = File.join(@rpath, "per_base_count.R")
      rscript = Cmd.new("Rscript #{script} -p #{@dir}")
      rscript.run
    end

    def per_base_quality_tile
      script = File.join(@rpath, "per_base_quality.R")
      rscript = Cmd.new("Rscript #{script} -p #{@dir}")
      rscript.run
    end

    def read_mean_quality
      script = File.join(@rpath, "read_mean_quality.R")
      rscript = Cmd.new("Rscript #{script} -p #{@dir}")
      rscript.run
    end

    def read_count
      script = File.join(@rpath, "read_counts.R")
      rscript = Cmd.new("Rscript #{script} -p #{@dir}")
      rscript.run
    end

    def synteny_plot
      script = File.join(@rpath, "synteny_plot.R")
      rscript = Cmd.new("Rscript #{script} -p #{@dir}")
      rscript.run
      puts "synteny plot"
      puts "#{rscript.stdout}"
      puts "#{rscript.stderr}"
    end

    def transrate_scores
      script = File.join(@rpath, "transrate_scores.R")
      rscript = Cmd.new("Rscript #{script} -p #{@dir}")
      rscript.run
    end


  end

end
