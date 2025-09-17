require "test_helper"

class ExperienceStreamCreationFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  
  setup do
    @user = create(:onboarded_user)
    @team = @user.current_team
    @space = @team.primary_space
    sign_in @user
  end
  
  test "user can create different types of experiences" do
    # Navigate to experiences page
    get account_team_space_experiences_path(@team, @space)
    assert_response :success
    
    # Create live stream experience
    assert_difference "Experience.count", 1 do
      post account_team_space_experiences_path(@team, @space), params: {
        experience: {
          name: "Live Coding Sessions",
          description: "Weekly coding streams",
          experience_type: "live_stream",
          price_cents: 2999
        }
      }
    end
    
    live_stream_exp = Experience.last
    assert_equal "live_stream", live_stream_exp.experience_type
    assert live_stream_exp.live_streaming?
    assert live_stream_exp.requires_real_time?
    
    # Create course experience
    assert_difference "Experience.count", 1 do
      post account_team_space_experiences_path(@team, @space), params: {
        experience: {
          name: "Rails Mastery Course",
          description: "Complete Rails training",
          experience_type: "course",
          price_cents: 19999
        }
      }
    end
    
    course_exp = Experience.last
    assert_equal "course", course_exp.experience_type
    refute course_exp.live_streaming?
    refute course_exp.requires_real_time?
    
    # Create consultation experience
    assert_difference "Experience.count", 1 do
      post account_team_space_experiences_path(@team, @space), params: {
        experience: {
          name: "1-on-1 Consultation",
          description: "Personal consultation sessions",
          experience_type: "consultation",
          price_cents: 49999
        }
      }
    end
    
    consultation_exp = Experience.last
    assert_equal "consultation", consultation_exp.experience_type
    refute consultation_exp.live_streaming?
    assert consultation_exp.requires_real_time?
  end
  
  test "user can update experience details" do
    experience = create(:experience, space: @space, name: "Original Name")
    
    # Go to edit page
    get edit_account_team_space_experience_path(@team, @space, experience)
    assert_response :success
    
    # Update experience
    patch account_team_space_experience_path(@team, @space, experience), params: {
      experience: {
        name: "Updated Experience",
        description: "New description",
        price_cents: 3999
      }
    }
    
    experience.reload
    assert_equal "Updated Experience", experience.name
    assert_equal "New description", experience.description
    assert_equal 3999, experience.price_cents
    
    follow_redirect!
    assert_response :success
  end
  
  test "user can create streams for live streaming experiences" do
    experience = create(:experience, 
      space: @space,
      experience_type: "live_stream"
    )
    
    # Navigate to streams page
    get account_team_space_experience_streams_path(@team, @space, experience)
    assert_response :success
    
    # Create new stream with mocked LiveKit service
    ExternalServiceMocks::LiveKit.mock_all! do
      assert_difference "Stream.count", 1 do
        post account_team_space_experience_streams_path(@team, @space, experience), params: {
          stream: {
            title: "Building a SaaS App",
            description: "Live coding session",
            scheduled_at: 2.days.from_now
          }
        }
      end
    end
    
    stream = Stream.last
    assert_equal "Building a SaaS App", stream.title
    assert_equal experience, stream.experience
    assert_equal "scheduled", stream.status
    assert_not_nil stream.scheduled_at
    
    follow_redirect!
    assert_response :success
  end
  
  test "user can update stream details" do
    experience = create(:experience, space: @space, experience_type: "live_stream")
    stream = create(:stream, experience: experience)
    
    # Go to edit page
    get edit_account_team_space_experience_stream_path(@team, @space, experience, stream)
    assert_response :success
    
    # Update stream
    patch account_team_space_experience_stream_path(@team, @space, experience, stream), params: {
      stream: {
        title: "Updated Stream Title",
        description: "New stream description",
        scheduled_at: 3.days.from_now
      }
    }
    
    stream.reload
    assert_equal "Updated Stream Title", stream.title
    assert_equal "New stream description", stream.description
    
    follow_redirect!
    assert_response :success
  end
  
  test "stream lifecycle transitions work correctly" do
    experience = create(:experience, space: @space, experience_type: "live_stream")
    stream = create(:stream, experience: experience, status: "scheduled")
    
    # Mock LiveKit for room operations
    ExternalServiceMocks::LiveKit.mock_all! do
      # Start stream
      assert stream.can_start?
      stream.start!
      assert_equal "live", stream.status
      assert_not_nil stream.started_at
      
      # End stream
      assert stream.can_end?
      stream.end!
      assert_equal "ended", stream.status
      assert_not_nil stream.ended_at
    end
  end
  
  test "user can create access passes for experiences" do
    experience = create(:experience, space: @space)
    
    # Navigate to access passes page
    get account_team_space_access_passes_path(@team, @space)
    assert_response :success
    
    # Create access pass
    assert_difference "AccessPass.count", 1 do
      post account_team_space_access_passes_path(@team, @space), params: {
        access_pass: {
          name: "VIP Access",
          description: "Full access to all content",
          price_cents: 9999,
          duration_days: 30,
          experience_ids: [experience.id]
        }
      }
    end
    
    access_pass = AccessPass.last
    assert_equal "VIP Access", access_pass.name
    assert_equal 9999, access_pass.price_cents
    assert_equal 30, access_pass.duration_days
    assert_includes access_pass.experiences, experience
    
    follow_redirect!
    assert_response :success
  end
  
  test "user can grant access to experiences" do
    experience = create(:experience, space: @space)
    access_pass = create(:access_pass, space: @space)
    access_pass.experiences << experience
    
    audience_user = create(:onboarded_user, first_name: "Audience", last_name: "Member")
    
    # Create access grant with mocked Stripe
    ExternalServiceMocks::Stripe.mock_all! do
      assert_difference "AccessGrant.count", 1 do
        post account_team_space_access_grants_path(@team, @space), params: {
          access_grant: {
            user_id: audience_user.id,
            access_pass_id: access_pass.id
          }
        }
      end
    end
    
    grant = AccessGrant.last
    assert_equal audience_user, grant.user
    assert_equal access_pass, grant.access_pass
    assert_not_nil grant.expires_at
    
    # Verify user has access to experience
    assert grant.grants_access_to?(experience)
  end
  
  test "experience deletion cascades to streams" do
    experience = create(:experience, space: @space, experience_type: "live_stream")
    stream1 = create(:stream, experience: experience)
    stream2 = create(:stream, experience: experience)
    
    # Delete experience
    assert_difference ["Experience.count", "Stream.count"], [-1, -2] do
      delete account_team_space_experience_path(@team, @space, experience)
    end
    
    # Streams should be gone
    assert_nil Stream.find_by(id: stream1.id)
    assert_nil Stream.find_by(id: stream2.id)
  end
  
  test "user cannot create invalid experiences" do
    # Try to create experience with missing required fields
    assert_no_difference "Experience.count" do
      post account_team_space_experiences_path(@team, @space), params: {
        experience: {
          name: "",
          description: "Description only",
          experience_type: nil,
          price_cents: nil
        }
      }
    end
    
    assert_response :unprocessable_entity
  end
  
  test "chat integration works with streams" do
    experience = create(:experience, space: @space, experience_type: "live_stream")
    stream = create(:stream, experience: experience)
    
    # Mock GetStream for chat operations
    ExternalServiceMocks::GetStream.mock_all! do
      # Chat room should be created for stream
      chat_room = stream.chat_room
      assert_not_nil chat_room
      assert_equal stream, chat_room.stream
      
      # User can join chat
      assert chat_room.can_join?(@user)
    end
  end
  
  test "complete experience creation to stream workflow" do
    # Create experience with mocked services
    ExternalServiceMocks.mock_all_services! do
      # Create experience
      post account_team_space_experiences_path(@team, @space), params: {
        experience: {
          name: "Complete Workshop",
          description: "End-to-end workshop",
          experience_type: "live_stream",
          price_cents: 4999
        }
      }
      
      experience = Experience.last
      
      # Create stream
      post account_team_space_experience_streams_path(@team, @space, experience), params: {
        stream: {
          title: "Workshop Session 1",
          description: "First session",
          scheduled_at: 1.day.from_now
        }
      }
      
      stream = Stream.last
      
      # Create access pass
      post account_team_space_access_passes_path(@team, @space), params: {
        access_pass: {
          name: "Workshop Pass",
          description: "Access to workshop",
          price_cents: 4999,
          duration_days: 7,
          experience_ids: [experience.id]
        }
      }
      
      access_pass = AccessPass.last
      
      # Grant access to a user
      audience_user = create(:onboarded_user)
      post account_team_space_access_grants_path(@team, @space), params: {
        access_grant: {
          user_id: audience_user.id,
          access_pass_id: access_pass.id
        }
      }
      
      grant = AccessGrant.last
      
      # Verify complete setup
      assert_equal @space, experience.space
      assert_equal experience, stream.experience
      assert_includes access_pass.experiences, experience
      assert grant.grants_access_to?(experience)
      assert stream.can_view?(audience_user)
    end
  end
end