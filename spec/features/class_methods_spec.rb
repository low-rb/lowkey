# frozen_string_literal: true

require_relative '../fixtures/class_methods'

RSpec.describe Lowkey::ClassMethods do
  subject(:class_methods) { file_proxy.definitions['Lowkey::ClassMethods'] }

  let(:file_proxy) { Lowkey.load('spec/fixtures/class_methods.rb') }

  it 'has inline class method' do
    expect(class_methods[:inline_class_method]).not_to be_nil
  end

  it 'has inline class method with arg' do
    expect(class_methods[:inline_class_method_with_arg]).not_to be_nil
  end

  it 'has class method' do
    expect(class_methods[:class_method_with_arg]).not_to be_nil
  end

  it 'has class method with arg' do
    expect(class_methods[:class_method_with_arg_and_default_value]).not_to be_nil
  end

  describe 'class methods' do
    it 'includes methods with a class name receiver' do
      expect(class_methods.class_methods.keys).to include(:named_class_method, :namespaced_class_method)
    end

    it 'includes methods in a singleton class of the class name' do
      expect(class_methods.class_methods.keys).to include(:named_singleton_class_method)
    end

    it 'excludes methods defined on other objects' do
      expect(class_methods.class_methods.keys).not_to include(:object_method, :object_singleton_class_method)
      expect(class_methods.instance_methods.keys).not_to include(:object_method, :object_singleton_class_method)
    end
  end

  describe '#receiver' do
    it 'is self for an inline class method' do
      expect(class_methods[:inline_class_method].receiver).to eq('self')
      expect(class_methods[:inline_class_method]).to be_receiver
    end

    it 'is the class name for a named class method' do
      expect(class_methods[:named_class_method].receiver).to eq('ClassMethods')
    end

    it 'is nil for a method in a singleton class' do
      expect(class_methods[:class_method_with_arg].receiver).to be_nil
      expect(class_methods[:class_method_with_arg]).not_to be_receiver
    end
  end
end
