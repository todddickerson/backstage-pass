module BulletTrain
  module Themes
    module BackstagePass
      # Matches the color list in app/assets/stylesheets/backstage_pass/tailwind/colors.css
      mattr_accessor :colors, default: %w[
        blue
        slate
        gray
        zinc
        neutral
        stone
        red
        orange
        amber
        yellow
        lime
        green
        emerald
        teal
        cyan
        sky
        indigo
        violet
        purple
        fuchsia
        pink
        rose
      ]

      class Theme < BulletTrain::Themes::Light::Theme
        def directory_order
          ["backstage_pass"] + super
        end
      end
    end
  end
end
