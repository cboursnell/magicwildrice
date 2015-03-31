#!/usr/bin/env	ruby

require 'helper'
require 'tmpdir'

class TestOases < Test::Unit::TestCase

  context 'Oases' do

    setup do
      @oases = MagicWildRice::Oases.new
    end

    teardown do
    end

    should "first make hash" do
      left  = File.join(File.dirname(__FILE__), 'data', 'test_1.fastq')
      right = File.join(File.dirname(__FILE__), 'data', 'test_2.fastq')
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          name = "test"
          @oases.create_hash(name, left, right)
          assert File.exist?(File.join(name, "Sequences")), "file exist"
        end
      end
    end

    should "second make graph" do
      left  = File.join(File.dirname(__FILE__), 'data', 'test_1.fastq')
      right = File.join(File.dirname(__FILE__), 'data', 'test_2.fastq')
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          name = "test"
          @oases.create_hash(name, left, right)
          @oases.create_graph(name)
          assert File.exist?(File.join(name, "contigs.fa")), "contigs exist"
        end
      end
    end

    should "then run oases" do
      left  = File.join(File.dirname(__FILE__), 'data', 'test_1.fastq')
      right = File.join(File.dirname(__FILE__), 'data', 'test_2.fastq')
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          name = "test"
          @oases.create_hash(name, left, right)
          @oases.create_graph(name)
          file = @oases.oases(name)
          puts file
          assert File.exist?(File.join(name, "transcripts.fa")), "transcripts exist"
        end
      end
    end

  end
end
