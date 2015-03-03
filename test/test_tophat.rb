#!/usr/bin/env  ruby

require 'helper'
require 'tmpdir'

class TestTophat < Test::Unit::TestCase

  context 'tophat' do

    setup do
      @tophat = MagicWildRice::Tophat.new
      @reference = File.join(File.dirname(__FILE__), 'data', 'chr01.fa')
    end

    teardown do
    end

    should "1 build index" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir tmpdir do |dir|
          @tophat.build_index @reference
          assert File.exist?("chr01.1.bt2")
          assert File.exist?("chr01.rev.2.bt2")
        end
      end
    end

    should "2 run tophat with reads" do
      left = File.join(File.dirname(__FILE__), 'data', 'test_1.fastq')
      right = File.join(File.dirname(__FILE__), 'data', 'test_2.fastq')
      Dir.mktmpdir do |tmpdir|
        Dir.chdir tmpdir do |dir|
          @tophat.build_index @reference
          @tophat.tophat left, right
          assert File.exist?("chr01.1.bt2")
          assert File.exist?("chr01.rev.2.bt2")
          assert File.exist?("tophat_chr01/accepted_hits.sam")
        end
      end

    end

    should "3 run cufflinks on tophat output" do
      left = File.join(File.dirname(__FILE__), 'data', 'test_1.fastq')
      right = File.join(File.dirname(__FILE__), 'data', 'test_2.fastq')
      Dir.mktmpdir do |tmpdir|
        Dir.chdir tmpdir do |dir|
          @tophat.build_index @reference
          @tophat.tophat left, right
          @tophat.cufflinks
          assert File.exist?("chr01.1.bt2")
          assert File.exist?("chr01.rev.2.bt2")
          assert File.exist?("tophat_chr01/accepted_hits.sam")
          assert File.exist?("tophat_chr01/transcripts.gtf")
          assert File.exist?("tophat_chr01/isoforms.fpkm_tracking")
        end
      end
    end

    should "4 create output fasta file" do
      left = File.join(File.dirname(__FILE__), 'data', 'test_1.fastq')
      right = File.join(File.dirname(__FILE__), 'data', 'test_2.fastq')
      Dir.mktmpdir do |tmpdir|
        Dir.chdir tmpdir do |dir|
          @tophat.build_index @reference
          @tophat.tophat left, right
          @tophat.cufflinks
          @tophat.assemble @reference
          assert File.exist?("chr01.1.bt2")
          assert File.exist?("chr01.rev.2.bt2")
          assert File.exist?("tophat_chr01/accepted_hits.sam")
          assert File.exist?("tophat_chr01/transcripts.gtf")
          assert File.exist?("tophat_chr01/isoforms.fpkm_tracking")
          assert File.exist?("tophat_chr01/chr01-transcripts.fa")
        end
      end
    end

  end
end
