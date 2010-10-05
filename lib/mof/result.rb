module MOF
class Result
  attr_reader :classes, :associations, :indications, :qualifiers, :instances
    
  def initialize
    @qualifiers = []
    @classes = []
    @associations = []
    @indications = []
    @instances = []
  end
  
  def is_qualifier? name
    !qualifier(name).nil?
  end
  private
  def join_to_s title, array
    s = ""
    if array.size > 0
      s << "\n// #{title} [#{array.size}]\n"
      s << array.join(";\n")
      s << ";"
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
end
