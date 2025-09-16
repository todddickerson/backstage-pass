FactoryBot.define do
  factory :access_pass_experience do
    association :access_pass
<<<<<<< HEAD
    experience { "MyString" }
    included { false }
=======
    association :experience
    included { true }
>>>>>>> main
    position { 1 }
  end
end
