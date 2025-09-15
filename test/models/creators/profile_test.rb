require 'test_helper'

class Creators::ProfileTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: 'test@example.com', password: 'password123')
    @profile = Creators::Profile.new(
      user: @user,
      username: 'testcreator',
      display_name: 'Test Creator'
    )
  end

  test "should be valid with valid attributes" do
    assert @profile.valid?
  end

  test "should require username" do
    @profile.username = nil
    assert_not @profile.valid?
    assert_includes @profile.errors[:username], "can't be blank"
  end

  test "should require display_name" do
    @profile.display_name = nil
    assert_not @profile.valid?
    assert_includes @profile.errors[:display_name], "can't be blank"
  end

  test "should normalize username to lowercase" do
    @profile.username = "TestCreator"
    @profile.save
    assert_equal "testcreator", @profile.username
  end

  test "should set display_name from username if blank" do
    @profile.display_name = nil
    @profile.username = "coolgamer"
    @profile.save
    assert_equal "Coolgamer", @profile.display_name
  end

  test "should validate username format" do
    @profile.username = "test@creator"
    assert_not @profile.valid?
    assert_includes @profile.errors[:username], "can only contain letters, numbers, underscore and dash"
  end

  test "should generate correct profile_url" do
    @profile.username = "mycoolname"
    assert_equal "/mycoolname", @profile.profile_url
  end

  test "should use username as to_param" do
    @profile.username = "mycoolname"
    assert_equal "mycoolname", @profile.to_param
  end

  test "should validate website_url format" do
    @profile.website_url = "not-a-url"
    assert_not @profile.valid?
    assert_includes @profile.errors[:website_url], "must be a valid URL"
  end

  test "should allow blank website_url" do
    @profile.website_url = ""
    assert @profile.valid?
  end

  test "should allow valid website_url" do
    @profile.website_url = "https://example.com"
    assert @profile.valid?
  end
end