
require 'fixwhich'

module MagicWildRice

  # downloads necessary data

  class Downloader

    def initialize(url)
      @url = url
      @curl = Which::which('curl').first
      @wget = Which::which('wget').first
      if !@curl and !@wget
        msg = "Don't know how to download files without curl or wget installed"
        raise RuntimeError.new(msg)
      end
    end

    def run
      if !already_extracted(@url)
        target = File.basename(@url)
        if !File.exist?(target)
          if !download
            return false
          end
        end
        if !extract(target)
          raise RuntimeError.new("extracting failed")
        end
      end
      return true
    end

    def download
      if @wget
        cmd = "wget #{@url} -O #{File.basename(@url)}"
      elsif @curl
        cmd = "curl #{@url} -L -o #{File.basename(@url)}"
      else
        raise RuntimeError.new("Neither curl or wget installed")
      end
      dl = Cmd.new cmd
      dl.run
      if !dl.status.success?
        puts "Download failed\n#{@url}\n#{stdout}\n#{stderr}\n"
        return false
      end
      return true
    end

    def extract(name)
      if name =~ /\.tar\.gz$/ or name =~ /\.tgz/
        cmd = "tar xzf #{name}"
      elsif name =~ /\.gz$/
        cmd = "gunzip #{name}"
      elsif name =~ /\.zip$/
        cmd = "unzip #{name}"
      elsif name =~ /\.sra$/
        cmd = "fastq-dump.2.3.5.2 --origfmt --split-3 #{name} --outdir #{output_dir}"
      else
        cmd = "echo extracted"
      end
      ex = Cmd.new cmd
      ex.run
      return ex.status.success?
    end

    def already_extracted url
      name = File.basename(url)
      if name =~ /\.sra$/
        if File.exist?("#{File.basename(url, ".sra")}.fastq") or
           File.exist?("#{File.basename(url, ".sra")}_1.fastq")
          return true
        end
        return false
      elsif name =~ /\.gz$/
        file = File.basename(name, ".gz")
      elsif name =~ /\.tar\.gz$/
        file = File.basename(name, ".tar.gz")
      elsif name =~ /\.zip$/
        file = File.basename(name, ".zip")
      else
        file = name
      end
      if File.exist?(file)
        return true
      else
        return false
      end
    end

  end

end