class Datapathy::Collection

  attr_reader :query, :model

  def initialize(query, elements = nil)
    @query, @model = query, query.model
    @elements = elements unless elements.nil?
  end

  def create(attributes)
    attributes = [attributes] if attributes.is_a?(Hash)
    resources = attributes.map do |attrs|
      model.new(attrs)
    end

    collection = self.class.new(query, resources)
    query.model.adapter.create(collection)
    resources.each { |r| r.new_record = false }
    
    resources.size == 1 ? resources.first : resources
  end

  def detect(&blk)
    select(&blk).first
  end
  alias find detect

  def select(&blk)
    query.add(&blk)
    self
  end
  alias find_all select

  def loaded?
    @elements
  end

  # Since @elements is an array, pretty much every array method should trigger
  # a load. The exceptions are the ones defined above.
  TRIGGER_METHODS = (Array.instance_methods - self.instance_methods).freeze
  TRIGGER_METHODS.each do |meth|
    class_eval <<-EVAL, __FILE__, __LINE__
      def #{meth}(*a, &b)
        self.load! unless loaded?
        @elements.#{meth}(*a, &b)
      end
    EVAL
  end

  def load!
    @elements = model.adapter.read(query).map { |r|
      model.new(r)
    }
  end

end