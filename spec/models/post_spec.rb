require 'spec_helper'

describe Forem::Post do
  let(:forum) { stub_model(Forem::Forum) }
  let(:topic) { stub_model(Forem::Topic, :forum => forum) }
  let(:post) { FactoryGirl.create(:post, :topic => topic) }
  let(:reply) { FactoryGirl.create(:post, :reply_to => post, :topic => topic) }

  context "upon deletion" do
    it "clears the reply_to_id for all replies" do
      reply.reply_to.should eql(post)
      post.destroy
      reply.reload
      reply.reply_to.should be_nil
    end
  end

  context "after creation" do
    it "subscribes the current poster" do
      @topic = FactoryGirl.create(:topic)
      @post = FactoryGirl.create(:post, :topic => @topic)
      @topic.subscriptions.last.subscriber.should == @post.user
    end

    it "does not email subscribers after post creation if not approved" do
      @post = FactoryGirl.build(:post, :topic => topic)
      @post.should_not be_approved
      @post.should_not_receive(:email_topic_subscribers)
      @post.save
    end

    it "only emails subscribers when post is approved" do
      @post = FactoryGirl.build(:post, :topic => topic)
      @post.should_receive(:email_topic_subscribers)
      @post.approve!
    end

    it "does not send out notifications if notifications have already been sent" do
      @post = FactoryGirl.create(:approved_post, :topic => topic)
      @post.should_not_receive(:email_topic_subscribers)
      @post.save
    end

    it "only emails other subscribers" do
      @user2 = FactoryGirl.create(:user)
      @topic = FactoryGirl.create(:topic)

      Forem::Subscription.any_instance.should_receive(:send_notification).once
      @post = FactoryGirl.build(:approved_post, :topic => @topic, :user => @user2)

      @post.save!
    end
  end

  context "helper methods" do
    it "retrieves the topic's forum" do
      post.forum.should == post.topic.forum
    end

    it "checks for post owner" do
      admin = FactoryGirl.create(:admin)
      assert post.owner_or_admin?(post.user)
      assert post.owner_or_admin?(admin)
    end
  end
end
