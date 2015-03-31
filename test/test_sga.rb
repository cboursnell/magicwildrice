#!/usr/bin/env	ruby

require 'helper'
require 'tmpdir'

class TestSGA < Test::Unit::TestCase

  context 'SGA' do

    setup do
      @sga = MagicWildRice::Sga.new
    end

    teardown do
    end

    # should "1 guess phred" do
    #   left  = File.join(File.dirname(__FILE__), 'data', 'test_1.fastq')
    #   a = @sga.guess_phred left
    #   assert_equal 64, a, "phred"
    # end

    # should "2 preprocess" do
    #   left  = File.join(File.dirname(__FILE__), 'data', 'test_1.fastq')
    #   right = File.join(File.dirname(__FILE__), 'data', 'test_2.fastq')
    #   # Dir.mktmpdir do |tmpdir|
    #   tmpdir = Dir.mktmpdir
    #   puts tmpdir
    #     Dir.chdir(tmpdir) do
    #       out = @sga.preprocess("test", left, right)
    #       assert_equal "test.fastq", out, "return name"
    #       assert File.exist?("test.fastq"), "file exists"
    #       assert File.stat("test.fastq").size > 10, "file size"
    #     end
    #   # end
    # end

    # should "3 index" do
    #   left  = File.join(File.dirname(__FILE__), 'data', 'test_1.fastq')
    #   right = File.join(File.dirname(__FILE__), 'data', 'test_2.fastq')
    #   # Dir.mktmpdir do |tmpdir|
    #   tmpdir = Dir.mktmpdir
    #   puts tmpdir
    #     Dir.chdir(tmpdir) do
    #       name = "test"
    #       out = @sga.preprocess(name, left, right)
    #       index = @sga.index1(name, left, right)

    #       assert_equal "test.fastq", out, "return prep"
    #       assert File.exist?("test.fastq"), "file exists"
    #       assert File.stat("test.fastq").size > 10, "file size"

    #       assert_equal "test.bwt", index, "return index"
    #       assert File.exist?("test.bwt"), "index file exists"
    #       assert File.stat("test.bwt").size > 10, "file size"

    #       assert File.exist?("test.sai"), "sai file exists"
    #     end
    #   # end
    # end

    # should "4 filter" do
    #   left  = File.join(File.dirname(__FILE__), 'data', 'test_1.fastq')
    #   right = File.join(File.dirname(__FILE__), 'data', 'test_2.fastq')
    #   # Dir.mktmpdir do |tmpdir|
    #   tmpdir = Dir.mktmpdir
    #   puts tmpdir
    #     Dir.chdir(tmpdir) do
    #       name = "test"
    #       out = @sga.preprocess(name, left, right)
    #       index = @sga.index1(name, left, right)
    #       filter = @sga.filter(name, left, right)

    #       assert_equal "test.fastq", out, "return prep"
    #       assert File.exist?("test.fastq"), "file exists"
    #       assert File.stat("test.fastq").size > 10, "file size"

    #       assert_equal "test.bwt", index, "return index"
    #       assert File.exist?("test.bwt"), "index file exists"
    #       assert File.stat("test.bwt").size > 10, "file size"

    #       assert File.exist?("test.filter.pass.fa"), "fasta passed exists"
    #       assert File.stat("test.filter.pass.fa").size > 10, "file size"
    #     end
    #   # end
    # end

    should "run sga" do
      left  = File.join(File.dirname(__FILE__), 'data', 'test_1.fastq')
      right = File.join(File.dirname(__FILE__), 'data', 'test_2.fastq')
      # Dir.mktmpdir do |tmpdir|
      tmpdir = Dir.mktmpdir
      puts tmpdir
        Dir.chdir(tmpdir) do
          name = "test"
          out = @sga.preprocess(name, left, right)
          index = @sga.index1(name, left, right)
          filter = @sga.filter(name, left, right)
          merge = @sga.fmmerge(name, left, right)
          index2 = @sga.index2(name, left, right)
          overlap = @sga.overlap(name, left, right)
          assemble = @sga.assemble(name, left, right)

          assert_equal "test.fastq", out, "return prep"
          assert File.exist?("test.fastq"), "file exists"
          assert File.stat("test.fastq").size > 10, "file size"

          assert_equal "test.bwt", index, "return index"
          assert File.exist?("test.bwt"), "index file exists"
          assert File.stat("test.bwt").size > 10, "file size"

          assert File.exist?("test.filter.pass.fa"), "fasta passed exists"
          assert File.stat("test.filter.pass.fa").size > 10, "file size"
        end
      # end
    end

  end
end
