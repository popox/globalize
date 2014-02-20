module Globalize
  module ActiveRecord
    module ActMacro
      def translates(*attr_names)
        return if translates?

        options = attr_names.extract_options!
        options[:unique_class] ||= nil
        options[:table_name] ||= "#{table_name.singularize}_translations"
        options[:foreign_key] ||= class_name.foreign_key
        options[:conditions] ||= ''

        class_attribute :translated_attribute_names, :translation_options, :fallbacks_for_empty_translations
        self.translated_attribute_names = attr_names.map(&:to_sym)
        self.translation_options        = options
        self.fallbacks_for_empty_translations = options[:fallbacks_for_empty_translations]

        include InstanceMethods
        extend  ClassMethods, Migration

        self.translation_class = options[:unique_class] unless options[:unique_class].nil?
        translation_class.table_name = options[:table_name] if translation_class.table_name.blank?

        has_many :translations, :class_name  => translation_class.name,
                                :foreign_key => options[:foreign_key],
                                :conditions  => options[:conditions],
                                :dependent   => :destroy,
                                :extend      => HasManyExtensions

        if options[:versioning]
          ::ActiveRecord::Base.extend(Globalize::Versioning::PaperTrail)

          translation_class.has_paper_trail
          delegate :version, :versions, :to => :translation
        end

        attr_names.each do |attr_name|
          translated_attr_accessor(attr_name)
          Globalize.send(:add_translatable, self, attr_name)
        end
      end

      def class_name
        @class_name ||= begin
          class_name = table_name[table_name_prefix.length..-(table_name_suffix.length + 1)].downcase.camelize
          pluralize_table_names ? class_name.singularize : class_name
        end
      end

      def translates?
        included_modules.include?(InstanceMethods)
      end
    end

    module HasManyExtensions
      def find_or_initialize_by_locale(locale)
        with_locale(locale.to_s).first || build(:locale => locale.to_s)
      end
    end
  end
end
