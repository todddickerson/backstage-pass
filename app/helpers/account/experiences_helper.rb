module Account::ExperiencesHelper
  # Returns Tailwind CSS classes for experience type badges
  def experience_type_badge_class(experience_type)
    case experience_type.to_s
    when "live_stream"
      "bg-red-100 text-red-800"
    when "course"
      "bg-blue-100 text-blue-800"
    when "community"
      "bg-purple-100 text-purple-800"
    when "consultation"
      "bg-green-100 text-green-800"
    when "digital_product"
      "bg-yellow-100 text-yellow-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end
end
