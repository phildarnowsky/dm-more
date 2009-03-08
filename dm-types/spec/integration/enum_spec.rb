require 'pathname'
require Pathname(__FILE__).dirname.parent.expand_path + 'spec_helper'

describe DataMapper::Types::Enum do
  before(:all) do
    # This silly hack is here because, somewhat surprisingly, before(all)
    # blocks get evaluated again before a nested context is run.  Since
    # Enum.[] returns a different anonymous subclass each time, the second
    # time that the definition of Resolution is encountered, the definition
    # has a different superclass even though the values are the same, which
    # causes a TypeError.

    begin
      Resolution
    rescue NameError
      class ::Resolution < Enum[:new, :fixed, :duplicate, :worksforme]
      end
    end

    class ::Bug
      include DataMapper::Resource

      property :id, Integer, :serial => true
      property :status, Enum[:crit, :warn, :info, :unknown]
      property :resolution, Resolution
    end
    Bug.auto_migrate!
  end

  it "should work" do
    repository(:default) do
      Bug.create(:status => :crit)
      Bug.create(:status => :warn)
    end

    bugs = Bug.all
    bugs[0].status.should == :crit
    bugs[1].status.should == :warn
  end

  it "should work with subclassed properties" do
    duplicate = Bug.create(:resolution => :duplicate)
    duplicate.resolution.should == :duplicate
  end

  it 'should immediately typecast supplied values' do
    Bug.new(:status => :crit).status.should == :crit
  end

  describe "with finders" do
    before(:all) do
      @info = Bug.create(:status => :info)
      @new = Bug.create(:resolution => :new)
    end
    it "should work with equality opeand" do
      Bug.all(:status => [:info, :unknown]).entries.should == [@info]
      Bug.all(:resolution => [:new, :worksforme]).entries.should == [@new]
    end
    it "should work with inequality operand" do
      Bug.all(:status.not => [:crit, :warn]).entries.should == [@info]
      Bug.all(:resolution.not => [:duplicate, :fixed]).entries.should == [@new]
    end
  end

  if defined?(Validate)
    describe 'with validation' do
      it "should accept crit status" do
        bug = Bug.new
        bug.status = :crit
        bug.should be_valid
      end

      it "should not accept blah status" do
        bug = Bug.new
        bug.status = :blah
        bug.should_not be_valid
        bug.errors.on(:status).should_not be_empty
      end
    end
  end
end
