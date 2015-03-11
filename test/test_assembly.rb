#!/usr/bin/env  ruby

require 'helper'
require 'yaml'

class TestAssembly < Test::Unit::TestCase

  context 'assembly' do

    setup do
      file = File.join(File.dirname(__FILE__), 'data', 'test.yaml')
      data = YAML.load(File.read(file))
      data.each do |info|
        info["files"].each_with_index do |file, index|
          info["files"][index] = File.expand_path(file)
        end
      end
      @assembly = MagicWildRice::Assembly.new data
    end

    teardown do
    end

    should "do assembly" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          @assembly.de_novo
          # input files
          assert File.exist?("IR-105460.fa")
          assert File.exist?("IR-105409.fa")
          assert File.exist?("IR-108773.fa")
          # contigs
          assert File.exist?("IR-105460/contig.fa")
          assert File.exist?("IR-105409/contig.fa")
          assert File.exist?("IR-108773/contig.fa")
        end
      end
    end

    should "run idba" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          idba = MagicWildRice::IdbaTrans.new
          left  = File.join(File.dirname(__FILE__), 'data', 'IR-105409_1.fq')
          right = File.join(File.dirname(__FILE__), 'data', 'IR-105409_2.fq')
          output = idba.run left, right
          assert File.exist?(output), "output file exists"
        end
      end
    end

    should "build command" do
      fasta_file = "input.fa"
      cmd = "-o input -r input.fa --num_threads --mink 21 --maxk 77 "
      cmd << "--step 4 --min_count 1 --no_correct --max_isoforms 6 "
      cmd << "--similar 0.98"
      idba = MagicWildRice::IdbaTrans.new
      ans = idba.build_cmd(fasta_file)
      assert_equal cmd, ans.split(" ")[1..ans.length].join(" "), "command"
    end

    should "convert fastq files to fasta" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          idba = MagicWildRice::IdbaTrans.new
          left  = File.join(File.dirname(__FILE__), 'data', 'IR-105409_1.fq')
          right = File.join(File.dirname(__FILE__), 'data', 'IR-105409_2.fq')
          output = idba.prepare_reads left, right
          assert_equal "IR-105409.fa", output, "output"
          assert File.exist?("IR-105409.fa"), "file exists"
        end
      end
    end

  end
end
