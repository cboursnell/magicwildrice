#!/usr/bin/env	ruby

require 'helper'

class TestRice < Test::Unit::TestCase

  context 'rice' do

    setup do
      file = File.join(File.dirname(__FILE__), 'data', 'test.yaml')
      @rice = MagicWildRice::MagicWildRice.new file
    end

    teardown do
    end

    should "load yaml file" do
      @rice.load_data
      files = @rice.files
      assert_equal 6, files.length, "length"
      assert_equal "S", files[0]["name"], "name"
      assert_equal "R", files[1]["name"], "name"
      assert_equal "G", files[2]["name"], "name"
      assert_equal "SR", files[3]["name"], "name"
      assert_equal "SG", files[4]["name"], "name"
      assert_equal "SGSR", files[5]["name"], "name"
      assert_equal "Oryza Sativa", files[0]["desc"], "desc"
    end

    # should "do fastqc" do
    #   @rice.load_data
    #   Dir.mktmpdir do |tmpdir|
    #     Dir.chdir(tmpdir) do
    #       @rice.fastqc
    #     end
    #   end
    # end

    should "make plots" do
      @rice.load_data
      # Dir.mktmpdir do |tmpdir|
      tmpdir = Dir.mktmpdir
      puts tmpdir
        Dir.chdir(tmpdir) do
          @rice.fastqc
          @rice.plots
        end
      # end

    end

  end
end
