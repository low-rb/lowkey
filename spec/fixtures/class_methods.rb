# frozen_string_literal: true

module Lowkey
  class ClassMethods
    def self.inline_class_method
      'goodbye'
    end

    def self.inline_class_method_with_arg(goodbye)
      goodbye
    end

    def ClassMethods.named_class_method = 'goodbye' # rubocop:disable Style/ClassMethods

    def (Lowkey::ClassMethods).namespaced_class_method = 'goodbye'

    OBJECT = Object.new
    def OBJECT.object_method = 'goodbye'

    class << OBJECT
      def object_singleton_class_method = 'goodbye'
    end

    class << ClassMethods
      def named_singleton_class_method = 'goodbye'
    end

    class << self
      def class_method_with_arg(goodbye)
        goodbye
      end

      def class_method_with_arg_and_default_value(goodbye = 'Bye')
        goodbye
      end
    end
  end
end
