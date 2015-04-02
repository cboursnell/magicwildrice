module MagicWildRice

  require 'fileutils'
  require 'fixwhich'

  class SoapDeNovo

    def initialize threads=8
      @threads = threads
      @soap = Which::which('SOAPdenovo-Trans-127mer').first
      raise "Can't find SOAPdenovo-Trans-127mer in path" if @soap.nil?
    end

    def run name, left, right
      @name = "soap_#{name}"
      path = "soap"
      config = make_config left, right
      soap = Cmd.new build_cmd config
      output = File.expand_path(File.join(path, "#{@name}.scafSeq"))
      FileUtils.mkdir_p(path)
      Dir.chdir(path) do
        unless File.exist?(output)
          soap.run
          unless soap.status.success?
            puts "Something went wrong with soap"
            puts soap.stderr
            puts soap.stdout
          end
        end
      end
      File.delete(config)
      return output
    end

    def make_config left, right
      str  = "max_rd_len=20000\n"
      str << "[LIB]\n"
      str << "avg_ins=250\n"
      str << "reverse_seq=0\n"
      str << "asm_flags=3\n"
      str << "q1=#{left}\n"
      str << "q2=#{right}\n"
      config = File.expand_path("#{@name}.config")
      File.open(config, "wb") { |out| out.write str }
      return config
    end

    def build_cmd config
      soap_cmd = "#{@soap} all "
      soap_cmd << "-s #{config} "             # config
      soap_cmd << "-o #{@name} "              # output
      soap_cmd << "-K 27 "
      soap_cmd << "-p #{@threads} "           # number of threads
      return soap_cmd
    end

    def lcs a # longest common substring
      s = a.min_by(&:size)
      lcs = catch(:hit) {
        s.size.downto(1) { |i|
          (0..(s.size - i)).each { |l|
            throw :hit, s[l, i] if a.all? { |item| item.include?(s[l, i]) }
          }
        }
      }
      lcs = "out" if lcs.length == 0
      if lcs[lcs.length-1]=~/[\_\-]/
        lcs = lcs[0..lcs.length-2]
      end
      return lcs
    end

  end

end
