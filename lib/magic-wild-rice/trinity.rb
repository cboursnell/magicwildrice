module MagicWildRice

  require 'fixwhich'

  class Trinity

    def initialize threads=8, memory="100G"
      @threads = threads
      @memory = memory
      @trinity = Which::which('Trinity').first
      abort "Can't find Trinity in path" if @trinity.nil?
    end

    def run name, left, right
      trinity = Cmd.new build_cmd name, left, right
      trinity.run
      @stdout = trinity.stdout
      @stderr = trinity.stderr
      if trinity.status.success?
        puts "success!"
      else
        puts "fail"
        puts @stdout
        puts @stderr
        abort
      end
      return "trinity_#{name}/Trinity.fasta"
    end

    def build_cmd name, left, right
      cmd = "#{@trinity}"
      cmd << " --seqType fq"
      cmd << " --max_memory #{@memory}"
      cmd << " --KMER_SIZE 27"
      cmd << " --left #{left}"
      cmd << " --right #{right}"
      # cmd << " --SS_lib_type FR" # only if reads are strand specific
      cmd << " --CPU #{@threads}"
      cmd << " --inchworm_cpu #{@threads}"
      cmd << " --min_contig_length 200"
      cmd << " --bypass_java_version_check"
      cmd << " --no_version_check"
      cmd << " --output trinity_#{name}"
    end

  end

end