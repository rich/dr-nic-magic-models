module DrNicMagicModels
  module Validations

    def generate_validations

      logger = DrNicMagicModels::Logger

      # Ensure that the connection to db is established, else validations don't get created.
      ActiveRecord::Base.connection
      
      # Code reworked from http://www.redhillconsulting.com.au/rails_plugins.html
      # Thanks Red Hill Consulting for using an MIT licence :o)

      # NOT NULL constraints
      self.columns.reject { |column| column.name =~ /(?i)^(((created|updated)_(at|on))|position|type|id)$/ }.each do |column|
        
        inheritable = false
        self.inheritable_attributes[:reflections].each_value{ |t| 
          if "#{t.name}_id" == column.name 
            inheritable = true
            logger.debug "validates_associated #{t.name}"
            self.validates_associated t.name, :allow_nil=>column.null, :allow_blank=>column.null
            break
          end
        }rescue 0
        
        if !inheritable
          if column.type == :integer
            logger.debug "validates_numericality_of #{column.name}, :allow_nil => #{column.null.inspect}, :only_integer => true"       
            self.validates_numericality_of column.name, :allow_nil => column.null, :only_integer => true
          elsif column.number?
            logger.debug "validates_numericality_of #{column.name}, :allow_nil => #{column.null.inspect}"
            self.validates_numericality_of column.name, :allow_nil => column.null
          elsif column.text? && column.limit
            logger.debug "validates_length_of #{column.name}, :allow_nil => #{column.null.inspect}, :maximum => #{column.limit}"
            self.validates_length_of column.name, :allow_nil => column.null, :maximum => column.limit
          end

          # Active record seems to interpolate booleans anyway to either true, false or nil...
          if column.type == :boolean
            logger.debug "validates_inclusion_of #{column.name}, :in => [true, false], :allow_nil => #{column.null}, :message => ActiveRecord::Errors.default_error_messages[:blank]"
            self.validates_inclusion_of column.name, :in => [true, false], :allow_nil => column.null, :message => ActiveRecord::Errors.default_error_messages[:blank]
          elsif !column.null
            #test if the column have a belongs_to association
            logger.debug "validates_presence_of #{column.name}"
            self.validates_presence_of column.name
          end
        end
      end

      # Single-column UNIQUE indexes
      get_unique_index_columns.each do |col|
        logger.debug "validates_uniqueness_of #{col}"
        self.validates_uniqueness_of col, :allow_nil=>true, :allow_blank=>true
      end                  

    end    
  end
end
