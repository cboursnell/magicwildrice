#!/usr/bin/env	ruby

require 'helper'

class TestFastqc < Test::Unit::TestCase

  context 'fastqc' do

    setup do
      @fastqc = MagicWildRice::Fastqc.new
    end

    teardown do
    end

    # should "do something" do
    # end

    should "count bases" do
      a = @fastqc.acgt_content("AAAACGTNY")
      assert_equal 1, a[0]["A"]
    end

    should "count kmers" do
      a = @fastqc.kmer_count ("ACGCGATGCTGC")
      assert_equal 1, a["ACGCGA"]
    end

    should "get read lengths" do
      @fastqc.length_hist("AAAAAAAAAAAAAAAAAAAAAAAAAA")
      @fastqc.length_hist("AAAAAAAAAAAAAAAAAAAAAAAAA\n")
      a = @fastqc.length_hist("AAAAAAAAAAAAAAAAAAAAAAAA\n")
      assert_equal 1, a[26]
      assert_equal 1, a[25]
      assert_equal 1, a[24]
    end

    should "get read quality per base" do
      qual = "BP\\cceeeggggghiiiifihihhhhhhffdghffhihhdfhfgfhhfhbXagfhihhhi"
      qual << "eghgggeeeeecbdd]`bccccccbbcbcabccc`cb^cc"
      a = @fastqc.quality qual
      qual = "BP\\ccacdggfgfhhiighiiihhifggeeccbb`^accac`bccccacc[bcdcccccccc"
      qual << "ccccccabc`abb`abbccccccaX[aaccccaaBBBB"
      a = @fastqc.quality qual
    end

    should "guess phred" do
      qual = "BPccceeeggggghiiiifihihhhhhhffdghffhihhdfhfgfhhfhbXagfhihhhi"
      qual << "eghgggeeeeecbdd]`bccccccbbcbcabccc`cb^cc"
      1001.times do
        @fastqc.guess_phred qual
      end
      @fastqc.read_count = 1000
      @fastqc.guess_phred qual
      @fastqc.guess_phred qual
      assert_equal 64, @fastqc.phred
    end

    should "create output files" do
      # Dir.mktmpdir do |tmpdir|
        # Dir.chdir(tmpdir) do |dir|
          file = File.join(File.dirname(__FILE__), 'data', 'test_1.fastq')
          @fastqc.run file
          @fastqc.read_length
          @fastqc.output
          assert File.exist?("test_1.fastq-per_base_composition.txt")
          assert File.exist?("test_1.fastq-per_base_quality.txt")
          assert File.exist?("test_1.fastq-read_length_hist.txt")
          assert File.exist?("test_1.fastq-read_count.txt")
        # end
      # end
    end

  end
end
