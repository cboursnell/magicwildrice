module MagicWildRice

  class Plots

    def initialize dir
      gem_dir = Gem.loaded_specs['magic-wild-rice'].full_gem_path
      @rpath = File.join(gem_dir, "lib", "R")
      @dir = dir
    end

    def run_r
      per_base_count
      per_base_quality_tile
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

  end

end
