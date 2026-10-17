# frozen_string_literal: true

require_relative '../models/source'

module Lowkey
  class SourceFactory
    class << self
      def file_source(root_node:, file_path:)
        end_line = root_node.respond_to?(:end_line) ? root_node.end_line : nil # TODO: Get file line count.

        Source.new(file_path:, scope: 'file', lines: root_node.script_lines, start_line: 1, end_line:)
      end

      def module_source(node:, namespace:, file_path:, lines:)
        start_line = node.respond_to?(:class_keyword_loc) ? node.class_keyword_loc.start_line : 1
        end_line = node.respond_to?(:end_keyword_loc) ? node.end_keyword_loc.end_line : start_line
        end_line = node.end_line if namespace == 'Object'
        scope = node.respond_to?(:name) ? node.name : 'Object'

        Source.new(file_path:, scope:, lines:, start_line:, end_line:)
      end

      def class_source(node:, file_path:, lines:)
        start_line = node.respond_to?(:class_keyword_loc) ? node.class_keyword_loc.start_line : 1
        end_line = node.respond_to?(:end_keyword_loc) ? node.end_keyword_loc.end_line : start_line

        Source.new(file_path:, scope: node.name, lines:, start_line:, end_line:)
      end

      def method_source(method_node:, file_path:, lines:)
        scope = method_node.name
        start_line = method_node.start_line
        end_line = method_node.end_line
        # TODO: Brittle conditional. What we really want to identify is if the method/rest of file was able to be parsed into an AST.
        end_line = end_line_from_indent(method_node:, lines:) if end_line >= lines.count

        Source.new(file_path:, scope:, lines:, start_line:, end_line:, location: method_node.location)
      end

      def param_source(param_node:, file_path:, lines:)
        scope = param_node.name
        start_line = param_node.start_line
        end_line = param_node.end_line

        Source.new(file_path:, scope:, lines:, start_line:, end_line:, location: param_node.location)
      end

      def return_source(return_node:, scope:, file_path:, lines:)
        start_line = return_node.start_line
        end_line = return_node.end_line

        Source.new(file_path:, scope:, lines:, start_line:, end_line:, location: return_node.location)
      end

      def body_source(method_source:)
        # TODO: Handle multi-line return proxy which increases body start line.
        start_line = method_source.start_line + 1
        end_line = method_source.end_line - 1

        Source.new(file_path: method_source.file_path, scope: method_source.scope, lines: method_source.lines, start_line:, end_line:)
      end

      def call_source(call_node:, file_path:, lines:)
        Source.new(file_path:, scope: call_node.name, lines:, start_line: call_node.start_line, end_line: call_node.end_line,
                   location: call_node.location)
      end

      def method_call_source(method_call_node:, arguments_node:, file_path:, lines:)
        pattern = arguments_node.arguments.first.content
        scope = "#{method_call_node.name.upcase} #{pattern}"
        start_line = method_call_node.start_line
        end_line = method_call_node.end_line

        Source.new(file_path:, scope:, lines:, start_line:, end_line:)
      end

      private

      # TODO: end_line = start_line if it's an endless method like "def method = expression".
      def end_line_from_indent(method_node:, lines:)
        end_index = nil

        index = method_node.start_line - 1
        indent = lines[index].split('def').first

        while end_index.nil?
          end_index = index if lines[index].nil?
          end_index = index if lines[index].start_with?("#{indent}end")
          index += 1
        end

        end_index + 1
      end
    end
  end
end
