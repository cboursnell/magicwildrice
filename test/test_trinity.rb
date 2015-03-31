#!/usr/bin/env	ruby

require 'helper'
require 'tmpdir'

class TestTrinity < Test::Unit::TestCase

  context 'Trinity' do

    setup do
      @trinity = MagicWildRice::Trinity.new
    end

    teardown do
    end

    should "build command" do
      left  = File.join(File.dirname(__FILE__), 'data', 'test_1.fastq')
      right = File.join(File.dirname(__FILE__), 'data', 'test_2.fastq')
      name = "test"
      ans = @trinity.build_cmd(name, left, right).split(" ")[1..-1].join(" ")
      cmd = "--seqType fq --max_memory 100G --KMER_SIZE 27 "
      cmd<<"--left /home/chris/documents/scripts/rice/test/data/test_1.fastq "
      cmd<<"--right /home/chris/documents/scripts/rice/test/data/test_2.fastq "
      cmd<<"--CPU 8 --inchworm_cpu 8 --min_contig_length 200 "
      cmd<< "--bypass_java_version_check --no_version_check "
      cmd<< "--output trinity_test"
      assert_equal cmd, ans, "command"
    end

    should "run trinity" do
      left  = File.join(File.dirname(__FILE__), 'data', 'test_1.fastq')
      right = File.join(File.dirname(__FILE__), 'data', 'test_2.fastq')
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          name = "test"
          @trinity.run name, left, right
          assert Dir.exist?("trinity_test"), "directory doesn't exist"
        end
      end
    end

  end
end
