require 'spec_helper'

describe EM::Twilio::Splitter do
  describe "#split" do
    it "does not partition fewer than 160 characters" do
      text = "1" * 159
      EM::Twilio::Splitter.new(text).to_a.should == [text]
    end

    it "paritions at the word boundary if longer than 160 characters" do
      word_1 = "1" * 150
      word_2 = "2" * 11
      EM::Twilio::Splitter.new(word_1 + " " + word_2).to_a.should == [word_1, word_2]
    end

    it "truncates word when it is longer than 160 characters" do
      word = "1" * 161
      expected = word[0..156] + "..."
      expected.size.should == 160
      EM::Twilio::Splitter.new(word).to_a.should == [expected]
    end

    it "partitions an example long message" do
      text = ("x" * 160) + " - leftover "
      EM::Twilio::Splitter.new(text).to_a.should == [
        "x" * 160,
        "- leftover"
      ]
    end

    it "ignores blank partitions" do
      text = ("x" * 160) + " \n\n\n"
      EM::Twilio::Splitter.new(text).to_a.should == [
        "x" * 160
      ]
    end
  end

end
