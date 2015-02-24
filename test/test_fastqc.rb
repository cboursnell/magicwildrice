#!/usr/bin/env	ruby

require 'helper'

class TestFastqc < Test::Unit::TestCase

  context 'fastqc' do

    setup do
      @fastqc = MagicWildRice::Fastqc.new
    end

    teardown do
    end

    should "count bases" do
      a = @fastqc.acgt_content("AAAACGTNY", "TTTTGCTNY")
      assert_equal 1, a[:left][0]["A"]
    end

    should "count kmers" do
      seq1 = "ACGCGATGCTGC"
      seq2 = "TAGCGATCGATC"
      a = @fastqc.kmer_count seq1, seq2
      assert_equal 1, a[:left]["ACGCGA"]
    end

    should "get read lengths" do
      seq1 = "A"*30
      seq2 = "T"*30
      a = @fastqc.length_hist seq1, seq2
      assert_equal 1, a[:left][30]
      assert_equal 1, a[:right][30]
    end

    should "get read quality per base" do
      qual1 = "BPbcceeeggggghiiiifihihhhhhhffdghffhihhdfhfgfhhfhbXagfhihhhi"
      qual1 << "eghgggeeeeecbdd]`bccccccbbcbcabccc`cb^cc"
      qual2 = "BPaccacdggfgfhhiighiiihhifggeeccbb`^accac`bccccacc[bcdcccccccc"
      qual2 << "ccccccabc`abb`abbccccccaX[aaccccaaBBBB"
      a = @fastqc.quality qual1, qual2
      assert_equal 1, a[:left][0][66]
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
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do |dir|
          file1 = File.join(File.dirname(__FILE__), 'data', 'test_1.fastq')
          file2 = File.join(File.dirname(__FILE__), 'data', 'test_2.fastq')
          @fastqc.run file1, file2
          read_length = @fastqc.read_length
          @fastqc.output
          assert_equal 100, read_length[:left][100], "read length"
          assert File.exist?("left/per_base_composition.txt"),
                             "per base composition file doesn't exist"
          assert File.exist?("left/per_base_quality.txt"),
                             "per_base_quality doesn't exist"
          assert File.exist?("read_length_hist.txt"),
                             "read_length_hist doesn't exist"
          assert File.exist?("left/read_count.txt"),
                             "read_count doesn't exist"
        end
      end
    end

  end
end
