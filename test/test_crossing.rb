#!/usr/bin/env  ruby

require 'helper'
require 'yaml'

class TestSynteny < Test::Unit::TestCase

  context 'synteny' do

    setup do
      file = File.join(File.dirname(__FILE__), 'data', 'test.yaml')
      data = YAML.load(File.read(file))
      @crossing = MagicWildRice::Crossing.new data
    end

    teardown do
    end

    should "do crossing" do
      puts "Done"
    end

    should "map reads" do
      @crossing.map
    end

  end
end
