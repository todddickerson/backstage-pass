class ApplicationController < ActionController::Base
  include Controllers::Base
  include DeviceDetection

  protect_from_forgery with: :exception, prepend: true
end
