module CIM
  class Schema
    attr_reader :classes, :associations, :indications, :qualifiers, :instances
    
    def initialize
      @qualifiers = []
      @classes = []
      @associations = []
      @indications = []
      @instances = []
    end
    
    def to_s
      "#{@qualifiers.join("\n")} #{@classes.join("\n")} #{@associations.join("\n")} #{@indications.join("\n")} #{@instances.join("\n")}"
    end
  end
end

