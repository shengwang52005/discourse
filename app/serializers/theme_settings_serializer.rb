# frozen_string_literal: true

class ThemeSettingsSerializer < ApplicationSerializer
  attributes :setting,
             :type,
             :default,
             :value,
             :description,
             :valid_values,
             :list_type,
             :textarea,
             :json_schema,
             :editor_component

  def setting
    object.name
  end

  def type
    object.type_name
  end

  def default
    object.default
  end

  def value
    object.value
  end

  def description
    locale_file_description =
      object
        .theme
        .internal_translations
        .find { |t| t.key == "theme_metadata.settings.#{setting}" }
        &.value
    locale_file_description || object.description
  end

  def valid_values
    object.choices
  end

  def include_valid_values?
    object.type == ThemeSetting.types[:enum]
  end

  def include_description?
    description.present?
  end

  def list_type
    object.list_type
  end

  def include_list_type?
    object.type == ThemeSetting.types[:list]
  end

  def textarea
    object.textarea
  end

  def include_textarea?
    object.type == ThemeSetting.types[:string]
  end

  def json_schema
    object.json_schema
  end

  def editor_component
    object.editor_component
  end

  def include_json_schema?
    object.type == ThemeSetting.types[:string] && object.json_schema.present?
  end

  def include_editor_component?
    object.editor_component.present?
  end
end
