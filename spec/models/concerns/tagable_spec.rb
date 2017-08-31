require 'rails_helper'

describe Tagable do

  module HasMany
    def has_many(*args)
    end
  end

  class TestTagable
    attr_reader :id
    extend HasMany
    include Tagable
    @@id = 0

    def initialize
      @@id += 1
      @id = @@id
    end
  end

  let(:test_tagable) { TestTagable.new }

  before(:all) do
    Tagging.skip_callback(:save, :after, :update_tagable_timestamp)
  end

  after(:all) do
    Tagging.set_callback(:save, :after, :update_tagable_timestamp)
  end

  it "Satisfies the tagable interface" do
    [Entity.new, Relationship.new, List.new].each do |tagable|
      expect(tagable).to respond_to(:tag)
      expect(tagable).to respond_to(:last_user_id)
    end
  end

  describe 'creating a tag' do
    it "creates a new tagging" do
      expect { test_tagable.tag("oil") }.to change { Tagging.count }.by(1)
    end

    it 'only creates one tagging per tag' do
      expect {
        test_tagable.tag("oil")
        test_tagable.tag("oil")
      }.to change { Tagging.count }.by(1)
    end

    it "creates a tagging with correct attributes" do
      test_tagable.tag("oil")
      attrs = Tagging.last.attributes
      expect(attrs['tag_id']).to eq 1
      expect(attrs['tagable_class']).to eq 'TestTagable'
      expect(attrs['tagable_id']).to eq test_tagable.id
    end
  end

  describe 'removing tags' do
    before{ test_tagable.tag("oil") }
    
    it 'removes a tag by name' do
      expect { test_tagable.remove_tag("oil") }.to change { Tagging.count }.by(-1)
    end

    
    it 'removes a tag by id' do
      expect { test_tagable.remove_tag(1) }.to change { Tagging.count }.by(-1)
    end
  end

  describe 'batch updating tags' do
        
    it 'adds tags in a batch with tags as ints' do
      expect { test_tagable.update_tags([1, 2]) }.to change { Tagging.count }.by(2)
    end

    it 'adds tags in a batch with tags as strings' do
      expect { test_tagable.update_tags(['1', '2']) }.to change { Tagging.count }.by(2)
    end
    
    it'removes tags in a batch' do
      test_tagable.tag('oil')
      test_tagable.tag('nyc')
      expect { test_tagable.update_tags([]) }.to change { Tagging.count }.by(-2)
    end

    it'adds and removes tags in a batch'  do
      test_tagable.tag('oil')
      test_tagable.update_tags(['2'])
      updated_tag_ids = test_tagable.tags.map { |t| t[:id] }
      expect(updated_tag_ids).to eql [2]
    end

    it 'returns self' do
      expect(test_tagable.update_tags([])).to be_a TestTagable
    end
  end
  
  
  it "retrieves tags applied to it" do
    test_tagable.tag("oil")
    expect(test_tagable.tags.to_a)
      .to eql [{ 'name' => "oil",
                 'description' => "the reason for our planet's demise",
                 'id' => 1 }]
  end

  it "doesn't retrieve tags applied to objects of other classes" do
    test_tagable.tag(1)
    expect(test_tagable.tags.length).to eq 1

    Tagging.create!(tag_id: 1, tagable_class: 'AnotherClass', tagable_id: test_tagable.id)
    expect(test_tagable.tags.length).to eq 1
  end

  it "retrieves taggings" do
    test_tagable.tag("oil")
    expect(test_tagable.taggings.to_a).to eq [Tagging.last]
  end

  it "can be tagged with an existing tag's id" do
    expect { test_tagable.tag(1) }.to change { Tagging.count }.by(1)
    expect(test_tagable.tags[0][:name]).to eq 'oil'
  end

  it "cannot be tagged with a non-existent tag id or name" do
    expect { test_tagable.tag("THIS IS NOT A REAL TAG!!!!") }.to raise_error(Tag::NonexistentTagError)
    expect { test_tagable.tag(1_000_000) }.to raise_error(Tag::NonexistentTagError)
  end
end