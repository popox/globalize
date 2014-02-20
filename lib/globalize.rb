require 'active_record'
require 'patches/active_record/xml_attribute_serializer'
require 'patches/active_record/query_method'

module Globalize
  autoload :ActiveRecord, 'globalize/active_record'
  autoload :Versioning,   'globalize/versioning'

  @@translatable = Hash.new

  class << self
    def translatable
      @@translatable ||= Hash.new
    end

    def add_translatable(klass, attr)
      if @@translatable.has_key? klass.name
        @@translatable[klass.name] << attr unless @@translatable[klass.name].include?(attr)
      else
        @@translatable[klass.name] = [attr]
    end

    def locale
      read_locale || I18n.locale
    end

    def locale=(locale)
      set_locale(locale)
    end

    def with_locale(locale, &block)
      previous_locale = read_locale
      begin
        set_locale(locale)
        result = yield(locale)
      ensure
        set_locale(previous_locale)
      end
      result
    end

    def with_locales(*locales, &block)
      locales.flatten.map do |locale|
        with_locale(locale, &block)
      end
    end

    def fallbacks?
      I18n.respond_to?(:fallbacks)
    end

    def fallbacks(locale = self.locale)
      fallbacks? ? I18n.fallbacks[locale] : [locale.to_sym]
    end

  protected

    def read_locale
      Thread.current[:globalize_locale]
    end

    def set_locale(locale)
      Thread.current[:globalize_locale] = locale.to_sym rescue nil
    end
  end
end

ActiveRecord::Base.extend(Globalize::ActiveRecord::ActMacro)
