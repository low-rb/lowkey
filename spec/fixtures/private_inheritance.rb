class Parent
  private

  def greet
    'hello'
  end
end

class Child < Parent
  def call_greet
    greet
  end
end