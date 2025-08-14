class ApplicationController < ActionController::Base
  include Pundit::Authorization
  
  # Allow browsers supporting our minimum requirements including Chrome 93+ and Safari 13+
  allow_browser versions: { chrome: 93, safari: 13, firefox: 90, edge: 93 }

  protected

  def after_sign_in_path_for(resource)
    admin_root_path
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end
end
