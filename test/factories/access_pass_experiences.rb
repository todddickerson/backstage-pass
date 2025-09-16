FactoryBot.define do
  factory :access_pass_experience do
    association :access_pass
    experience { "MyString" }
    included { false }
    position { 1 }
  end
end
