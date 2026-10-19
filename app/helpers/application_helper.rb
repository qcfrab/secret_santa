module ApplicationHelper
  def field_class(resource, attr)
    "input-error" if resource.errors[attr].any?
  end

  def field_error(resource, attr)
    message = resource.errors[attr].first
    return if message.blank?

    content_tag(:p, message, class: "field-error")
  end
end