#  J-_-L

require 'has_many_booleans/simple_bitset'

module HasManyBooleans #:nodoc:
  RAILS2  = if ENV['RAILS_GEM_VERSION']
    ENV['RAILS_GEM_VERSION'] < '3'
else
    true
  end

  module ClassMethods
    #=== Setup the booleans for a model
    #The method takes the symbols of the desired booleans as parameters. As last
    #parameter you can apply an options hash. Each symbol represents an index,
    #<em>depending on the position</em> in the list, starting with 1.
    #
    #   class Model < ActiveRecord::Base
    #     has_many_booleans :name, :password,
    #       :true => [      :name ],
    #       :append => 'set',
    #   end
    #
    #Another way of setting up the booleans is with an hash. This is useful when
    #you want to choose the indexes yourself.
    #
    #   class Model < ActiveRecord::Base
    #     has_many_booleans({:name => 23, :password => 99},
    #       :append => 'set')
    #   end
    #
    #==== Available options
    #
    #[<tt>:true</tt>] Takes an array of boolean names which shall default to +true+.
    #[<tt>:append</tt>] The name to append to the listed booleans. The underscore is added automatically. +nil+ is also possible. Default is +activated+.
    #[<tt>:field</tt>] The database field used. Defaults to +booleans+.
    #[<tt>:suffixes</tt>] Specifies, which "alias" methods are created. Defaults to <tt>["?", "=", "!"]</tt>. You cannot add new ones, you can only forbid some of them.
    #[<tt>:false_values</tt>] All the values in the array can be used to set a boolean to +false+ (when used with the <tt>=</tt> method). <b>Example:</b> Set this to <tt>["0"]</tt> and then call <tt>some_boolean_activated = "0"</tt>, it will set the boolean to +false+. Default settings is +false+ (deactivated).
    #[<tt>:lazy</tt>]  When the <tt>:lazy</tt> option is set to +false+, the bitset integer gets changed every time you assign a new value for a boolean. The default setting is +true+, which means, the integer gets only updated when the object is saved.
    #[<tt>:self</tt>] This is just another virtual boolean. You can freely assign the name. It is always stored as first bit in the bitset integer (so if the bitset integer is odd, this special boolean is set). You can also set this to +true+, which means, the <tt>:append</tt> value is used as method name. Default: +false+.
    #[<tt>:self_value</tt>] The default value for the special <tt>:self</tt> boolean above.
    def has_many_booleans(*params)

      # get params
      if params.last.is_a? Hash # booleans_options
        parse_booleans_options params.pop

        if params.empty?
          warn "has_many_booleans: You applied a single hash as parameter, which gets interpreted as option hash. If you wish to use it as boolean hash, give a {} as second parameter!"
        end
      else
        parse_booleans_options Hash.new
      end

      if params.first.is_a? Hash # alternative usage with a hash instead of array
        params = params.first
        iter_method = :each
      else
        iter_method = :each_with_index
      end

      # data structure: { string => [index, boolean_value] }
      @booleans_default = {}
      params.send(iter_method){ |key, index|
        index = index.to_i+1
        @booleans_default[key.to_s] = [ index,
          @booleans_options[:true].include?(key.to_sym) ||
          @booleans_options[:true].include?(key.to_s)
        ] if index > 0
      }

      # validators
      @booleans_validators = { true => [], false => [] }

      send :include, InstanceMethods

      # hook in callbacks part 1 (to not overwrite after_initialize)
      class << self
        def instantiate_with_booleans(record) #:nodoc:
            object = instantiate_without_booleans record
            object.initialize_booleans
            object
        end
        alias_method_chain :instantiate, :booleans
      end

      before_save :save_booleans

      # register scopes
      booleans_scope = lambda{ |true_or_false, *args|
        indexes = if args.blank?
           [1] # special self boolean
        else
          args.map{ |name|
            if name == nil # allow self in "or" connection
              1
            else
              name = name.to_s
              if !@booleans_default[name]
                warn 'has_many_booleans: You are using unknown boolean names in your scope!'
              else
                2 ** @booleans_default[name][0]
              end
            end
          }.compact
        end
        cond = ["#{@booleans_options[:field]} & ?#{' < 1' if !true_or_false}"]*indexes.size*' or '
        if RAILS2
          {:conditions => [cond, *indexes]}
        else
          where cond, *indexes
        end
       }

      scope_name = RAILS2 ? :named_scope : :scope

      send scope_name, :true, lambda { |*args|
        booleans_scope[true, *args]
      }

      send scope_name, :false, lambda { |*args|
        booleans_scope[false, *args]
      }
    end

    alias :hmb :has_many_booleans

    # getters
    def booleans_options #:nodoc:
      @booleans_options
    end

    def booleans_default #:nodoc:
      @booleans_default
    end

    def booleans_validators #:nodoc:
      @booleans_validators
    end

    # List all booleans that are required to be false!
    #   validates_false :description, :password
    def validates_false(*bools)
      booleans_validators[false] = bools
      validate :validator_false
    end

    # List all booleans that are required to be true!
    #   validates_false :description, :password
    def validates_true(*bools)
      booleans_validators[true] = bools
      validate :validator_true
    end

    private

    def parse_booleans_options(new_booleans_options)
      # std booleans_options
      @booleans_options = {
        :append   => '_activated',
        :field    => 'booleans',
        :suffixes => %w| ! = ? |,
        :true     => [],
        :false_values => [], # e.g. [0, "0", ""],
        :self     => false,
        :self_value => false,
        :lazy     => true,
      }

      # parse params
      new_booleans_options.each{|opt_name, opt_value|
        if @booleans_options.has_key? opt_name

          @booleans_options[opt_name] = case opt_name

          when :append # prepend underscore
            opt_value ? "_#{opt_value}" : ''

          when :suffixes # only allow ! = ?
            (opt_value||[]) & %w| ? ! = |

          when :false_values
            opt_value || []

          when :self_value, :lazy # normalize
            !!opt_value
          else
            opt_value
          end
        end
      }
    end
  end

  module InstanceMethods #:nodoc: callbacks

    # Load boolean integer from database and define the methods.
    def initialize_booleans
      booleans_field  = self.class.booleans_options[:field]
      booleans_activated = self[booleans_field] ? self[booleans_field].to_bra : []

      @booleans_data = { nil => [0, false] } # self@nil

      self.class.booleans_default.each{ |name, (index, value)|
        name = name.to_s

        each_suffix{ |suffix|
          # get values
          init_value = if self.new_record?
            self.class.booleans_options[:true].member?(name.to_sym)
          else
            booleans_activated.member?(index)
          end
          @booleans_data[name] = [index, init_value]

          # define the methods
          method_name = name + self.class.booleans_options[:append] + suffix
          define_boolean_method method_name, suffix, name

          # define the self method
          if self.class.booleans_options[:self]
            # get value
            if self.new_record?
              cond = self.class.booleans_options[:self_value]
            else
              cond = booleans_activated.member? 0
            end
            @booleans_data[nil][1] = cond ? true : false

            # get self method name
            self_method = if self.class.booleans_options[:self] === true
              if !self.class.booleans_options[:append] || self.class.booleans_options[:append].empty?
                raise "has_many_booleans: self method activated with true, but :append is nil! Please use :self => 'method_name'"
              else
                self.class.booleans_options[:append][1..-1]
              end
            else
              self.class.booleans_options[:self]
            end

            each_suffix{ |suffix|
              define_boolean_method self_method + suffix, suffix
            }
          end
        }
      }
    end

    # Transform booleans to integer and save in the database.
    def save_booleans
      act = []
      @booleans_data.each{ |_, (index, value)|
        act << index if value
      }
      self[self.class.booleans_options[:field]] = act.to_bri
    end

    private

    def define_boolean_method(method_name, suffix, name=nil)
      if self.respond_to?(method_name)
        #warn "has_many_booleans: Could not define #{method_name} for #{self.class} (method already exists)"
      else
        self.class.send(:define_method, method_name) do |*new_value|
          case suffix
          when '', '?'
            # nothing's changed
          when '!'
            @booleans_data[name][1] = true
            save_booleans  if !self.class.booleans_options[:lazy]
          when '='
            @booleans_data[name][1] =
            !!( new_value[0] && !self.class.booleans_options[:false_values].member?(new_value[0]) )
            save_booleans  if !self.class.booleans_options[:lazy]
          end
          @booleans_data[name][1]
        end
      end
    end

    def each_suffix(&block)
      ( [''] + self.class.booleans_options[:suffixes] ).each{ |suffix|
        yield suffix
      }
    end



    # hook in callbacks part 2 (to not overwrite after_initialize)
    #TODO run callback after booleans have been fetched
    def initialize(*args, &block) # :nodoc:
      super *args, &block
      initialize_booleans
    end

    if respond_to? :initialize_copy
      def initialize_copy(record)
        object = super record
        initialize_booleans
        object
      end
    end


    # validators
    def validator_true
      self.class.booleans_validators[true].each { |bool|
        bd = @booleans_data[bool.to_s]
        errors.add("Boolean #{bool}", "must be true")  if bd && !(bd[1])
      }
    end

    def validator_false
      self.class.booleans_validators[false].each { |bool|
        bd = @booleans_data[bool.to_s]
        errors.add("Boolean #{bool}", "must be false")  if bd && bd[1]
      }
    end

  end

  # activate class methods
  def self.included(base) #:nodoc:
    base.class_eval do
      extend ClassMethods
    end
  end
end

# activate instance methods
ActiveRecord::Base.send :include, HasManyBooleans

# Copyright (c) 2010 Jan Lelis http://rbjl.net, released under the MIT license
#  available at http://github.com/janlelis/has_many_booleans

