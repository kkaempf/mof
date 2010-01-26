class MofResult
  attr_reader :classes, :associations, :indications, :qualifiers, :instances
    
  def initialize
    @qualifiers = []
    @classes = []
    @associations = []
    @indications = []
    @instances = []
  end
  
  def qualifier name
    return name if name.is_a?(CIM::Meta::Qualifier)
    name = name.to_s
    @qualifiers.each do |q|
      return q if q.name.casecmp(name) == 0
    end
    nil
  end
  def is_qualifier? name
    !qualifier(name).nil?
  end
  private
  def join_to_s title, array
    s = ""
    if array.size > 0
      s << "\n// #{title} [#{array.size}]\n"
      s << array.join("\n")
    end
    s
  end
  public
  def to_s
    s = join_to_s( "Qualifiers", @qualifiers )
    s << join_to_s( "Classes", @classes )
    s << join_to_s( "Associations", @associations )
    s << join_to_s( "Indications", @indications )
    s << join_to_s( "Instances", @instances )
    s
  end
end

