#!/usr/bin/env	ruby

require 'helper'
require 'tmpdir'

class TestSoap < Test::Unit::TestCase

  context 'Soap' do

    setup do
      @soap = MagicWildRice::SoapDeNovo.new
    end

    teardown do
    end

    should "make config" do
      left  = File.join(File.dirname(__FILE__), 'data', 'test_1.fastq')
      right = File.join(File.dirname(__FILE__), 'data', 'test_2.fastq')
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          output = @soap.make_config left, right
          assert File.exist?(output), "file exists"
        end
      end
    end

    should "build command" do
      cmd = @soap.build_cmd "test.config"
      ans = "SOAPdenovo-Trans-127mer all -s test.config -o test -K 27 -p 8"
      a = cmd.split(" ")
      a[0] = File.basename(a[0])
      assert_equal ans, a.join(" "), "command"
    end

    should "run soap" do
      left  = File.join(File.dirname(__FILE__), 'data', 'test_1.fastq')
      right = File.join(File.dirname(__FILE__), 'data', 'test_2.fastq')
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          ans = @soap.run left, right
          assert File.exist?(ans), "contigs exist"
          assert File.exist?("test.contig"), "config exists"
        end
      end
    end

  end
end
