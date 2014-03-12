require 'render_anywhere'
module RailsAdminGenericRender
  include RenderAnywhere
  extend ActiveSupport::Concern

  included do
    def method_missing(method_sym, *_arguments, &_block)
      match = method_sym.to_s.match(/render_(.+)/)
      if match && match[1]
        set_instance_variable(:object, self)
        render template: "#{self.class.name.underscore.downcase.pluralize}/#{match[1]}", layout: false
      else
        super
      end
    end
  end
end
