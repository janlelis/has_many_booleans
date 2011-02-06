require File.expand_path( File.dirname(__FILE__) + '/test_helper' )

class HasManyBooleansTest < ActiveSupport::TestCase
  load_schema

  # # #
  # create all kinds of model classes
  #
  class Default < ActiveRecord::Base
    has_many_booleans :name, :password, :admin,
                      :true => [:name, :password],
                      :append => 'bla'
  end

  class ManyOption < ActiveRecord::Base
    has_many_booleans :a, :b, :admin, :name, :password,
            :true => [    :b],
        :suffixes => %w| 1 2 3 1 2 ? ! = . k l |,
        :append   => '145',
        :self     => true,
        :lazy     => false
  end

  class NoOption < ActiveRecord::Base
    has_many_booleans :name, :password, :admin
  end

  class Hmb < ActiveRecord::Base
    hmb :name, :password, :admin, :append => 'blubb'
  end

  class BooleansAsHash < ActiveRecord::Base
    has_many_booleans({ :name     => 22,
                        :password => 5,
                        :admin    => 7 },
                      :append => 'bla')
  end

  class Append < ActiveRecord::Base
    has_many_booleans :name, :password, :admin, :append => 'bla'
  end

  class AppendNil < ActiveRecord::Base
    has_many_booleans :name, :password, :admin, :append => nil
  end

  class Field < ActiveRecord::Base
    has_many_booleans :name, :password, :admin, :field => 'bools'
  end

  class SuffixNone < ActiveRecord::Base
    has_many_booleans :name, :password, :admin, :suffixes => nil
  end

  class SuffixEqualOnly < ActiveRecord::Base
    has_many_booleans :name, :password, :admin, :suffixes => ['=']
  end

  class SuffixQuestionOnly < ActiveRecord::Base
    has_many_booleans :name, :password, :admin, :suffixes => ['?']
  end

  class SuffixExclamationOnly < ActiveRecord::Base
    has_many_booleans :name, :password, :admin, :suffixes => ['!']
  end

  class Self < ActiveRecord::Base
    has_many_booleans :name, :password, :admin, :self => true
  end

  class SelfAppendNil < ActiveRecord::Base
    has_many_booleans :name, :password, :admin, :self => true, :append => nil
  end

  class SelfName < ActiveRecord::Base
    has_many_booleans :name, :password, :admin, :self => 'active_', :self_value => true
  end

  class ValidateTest < ActiveRecord::Base
    has_many_booleans :name, :password, :admin

    validates_true  :name
    validates_false :password
  end

  class ArCallback < ActiveRecord::Base
    has_many_booleans :name, :password, :admin
    after_initialize :cb_after_initialize
    before_save :cb_before_save

    def cb_after_initialize
      self.name = "Yukihiro"
    end

    def cb_before_save
      self.name = 'matz'
    end
  end

  class LazyFalse < ActiveRecord::Base
    has_many_booleans :name, :password, :admin, :lazy => false
  end

  class FalseValue < ActiveRecord::Base
    has_many_booleans :name, :password, :admin, :false_values => ["super", 'toll', 3]
  end

  class UnknownValue < ActiveRecord::Base
    has_many_booleans :name, :password, :admin, :unkown_value => false
  end

  class Scope < ActiveRecord::Base
    has_many_booleans :name, :password, :admin, :self => true
  end

  # # #
  # instances helpers
  #
  def create_instances
    @instances = {
      :default                       => Default.new,
      :many_option                   => ManyOption.new,
      :no_option                     => NoOption.new,
      :booleans_as_hash              => BooleansAsHash.new,
      :hmb                           => Hmb.new,
      :append                        => Append.new,
      :append_nil                    => AppendNil.new,
      :field                         => Field.new,
      :suffix_none                   => SuffixNone.new,
      :suffix_question_only          => SuffixQuestionOnly.new,
      :suffix_equal_only             => SuffixEqualOnly.new,
      :suffix_exclamation_only       => SuffixExclamationOnly.new,
      :self                          => Self.new,
      :self_name                     => SelfName.new,
      :ar_callback                   => ArCallback.new,
      :lazy_false                    => LazyFalse.new,
      :false_value                   => FalseValue.new,
      :unknown_value                 => UnknownValue.new,
    }
  end

  def create_instance(which, *params)
    @a = which.new *params
    @o = which.booleans_options
  end

  def loop_instances(with_assign = false)
    @instances.each{ |name, instance|
      @n, @a = name, instance
      @o     = @a.class.booleans_options
      next if with_assign &&( !@o[:suffixes].include?('=') || !@o[:append] ||  @o[:append].empty?) # or name does not work (existing method overwrite protection)
      yield
    }
  end

  # helper for often called methods
  def snd(attr_name, suffix = '', value = nil)
    if suffix == '='
      @a.send( "#{attr_name}#{@o[:append] || ''}#{suffix}", value)
    else
      @a.send "#{attr_name}#{@o[:append] || ''}#{suffix}"
    end
#  rescue => e
 #   p "#{e} -- #{@a}  -- #{@o}"
  end

  # # #
  # weak test of setup
  #
  test 'create_instances' do
    assert_nothing_raised{
       assert_kind_of @a.class, @a
     }
  end

  # # #
  # class methods
  #
  test 'booleans_options get parsed the right way' do
    create_instance ManyOption
    assert_equal @o[:append],                               '_145'
    assert_equal @o[:true],                                 [:b]
    assert_equal (@o[:suffixes]||[]).sort, %w| ! = ? |
  end

  # # #
  # general behaivour
  #
  test 'methods exist' do
    create_instances and loop_instances do
      assert_nothing_raised         { snd :name }
      assert_raise( NoMethodError ) { snd :dont_know_this_attr }
      assert_raise( NoMethodError ) { @a.send :name_ru903gfjh209gh3209p23 }
    end
  end

  test 'different instances' do
    create_instance NoOption
    a = @a
    snd :name, '=', true
    create_instance NoOption
    assert a.name_activated
    assert_not snd :name

    create_instance SelfName
    a = @a
    a.active_ = false
    create_instance SelfName
    assert @a.active_
    assert_not a.active_
  end

  test 'set and unset (with =)' do
    create_instances and loop_instances(true) do
                  ( snd :name, '=', false )#, "#{@a.class},#{p :O;snd :name, '=', false}"
      assert_not    (snd :name), "#{@a}, #{snd :name}"
                    snd :name, '=', true
      assert        snd :name

                    snd :password, '=', false
      assert_not    snd :password
                    snd :password, '=', true
      assert        snd :password
    end
  end

  test 'save and load (with =)' do
    create_instances and loop_instances(true) do
      [:name, :password].each{ |what|
        snd what, '=', false
        assert              @a.save
        tmp = @a.class

        assert_instance_of  tmp, (@a = @a.class.last)
        assert_not          snd what

        snd what, '=', true
        assert              @a.save
        tmp = @a.class

        assert_instance_of  tmp, (@a = @a.class.last)
        assert              snd what
      }
    end
  end

  test 'right default values' do
    create_instance Default
    assert        snd :name
    assert        snd :password
    assert_not    snd :admin
  end

  test "dont overwrite existing attrs" do
    create_instance AppendNil
    @a.name = 'Yukihiro'
    assert @a.save
    @a = AppendNil.last
    assert_equal @a.name, 'Yukihiro'
  end

  test 'ar callbacks work' do
    create_instance ArCallback
    assert_equal @a.name, 'Yukihiro'
    assert @a.valid?
    @a.save
    assert_equal @a.name, 'matz'
  end

  test 'Model.new works' do
    @a = ArCallback.new :name_activated => true, :name => 'Hildegard', :password => '123'

    assert @a.name_activated
    assert_equal @a.name,     'Hildegard'
    assert_equal @a.password, '123'
  end

  # # #
  # booleans_options
  #
  test 'suffixes' do
    create_instance SuffixNone
    assert_nothing_raised         { snd :name }
    assert_raise( NoMethodError ) { snd :name, '?' }
    assert_raise( NoMethodError ) { snd :name, '!' }
    assert_raise( NoMethodError ) { snd :name, '=' }
    assert_raise( NoMethodError ) { snd :name, '=', 9999 }

    create_instance SuffixQuestionOnly
    assert_nothing_raised         { snd :name }
    assert_nothing_raised         { snd :name, '?' }
    assert_raise( NoMethodError ) { snd :name, '!' }
    assert_raise( NoMethodError ) { snd :name, '=' }
    assert_raise( NoMethodError ) { snd :name, '=', 9999 }

    create_instance SuffixExclamationOnly
    assert_nothing_raised         { snd :name }
    assert_raise( NoMethodError ) { snd :name, '?' }
    assert_nothing_raised         { snd :name, '!' }
    assert_raise( NoMethodError ) { snd :name, '=' }
    assert_raise( NoMethodError ) { snd :name, '=', 9999 }

    create_instance SuffixEqualOnly
    assert_nothing_raised         { snd :name }
    assert_raise( NoMethodError ) { snd :name, '?' }
    assert_raise( NoMethodError ) { snd :name, '!' }
    assert_nothing_raised         { snd :name, '=' }
    assert_nothing_raised         { snd :name, '=', 9999 }
  end

  test 'self' do
    create_instance Default
    assert_raise( NoMethodError ) { @a.send @o[:append] }

    create_instance Self
    assert_nothing_raised         { @a.send @o[:append][1..-1] }
    assert_equal @a.send( @o[:append][1..-1] ), false
    @a.send( @o[:append][1..-1] + '=', 324 )
    assert_equal @a.send( @o[:append][1..-1] ), true

    assert_raise( RuntimeError )  {
      create_instance SelfAppendNil
    }

    create_instance SelfName
    assert_nothing_raised         { @a.send @o[:self] }
    assert_equal @a.send( @o[:self] ), true
  end

  test "lazyness (with assign)" do
    create_instances and loop_instances(true) do
      remember = @a.send( @o[:field] )
      snd( :name, '=', !snd(:name) )
      if @o[:lazy] # normal setting
        assert_equal      remember, @a.send( @o[:field] )
      else
        assert_not_equal  remember, @a.send( @o[:field] )

      end
    end
  end

  test "false_values (with assign)" do
    create_instance FalseValue

                snd :name, '=', true
                snd :name, '=', 'super'
    assert_not  snd :name
                snd :name, '=', 3
    assert_not  snd :name
                snd :name, '=', 99
    assert      snd :name
  end

#  test "unknown value" do
#    create_instance UnknownValue

#                snd :name, '=', true
#                snd :name, '=', 'not in true values'
#    assert_not  snd :name
#                snd :name, '=', 'true'
#    assert      snd :name
#  end

  # scopes
  test 'scopes' do
    # create dummy data
    create_instance Scope #1
      @a.save
    create_instance Scope #2
      @a.activated!
      @a.password_activated!
      @a.save
    create_instance Scope #3
      @a.activated!
      @a.save
    create_instance Scope #4
      @a.password_activated!
      @a.save
    create_instance Scope #5
      @a.name_activated!
      @a.save

    # test queries
    assert_equal Scope.true(:name),                 [Scope.find(5)]
    assert_equal Scope.false,                       Scope.find(1, 4, 5)
    assert_equal Scope.true(:name, :password),      Scope.find(2, 4, 5)
    assert_equal Scope.true(:name).true(:password), []
  end

  # validations
  test 'validates_true' do
    create_instance ValidateTest

                snd :password, '=', false
                snd :name,     '=', false
    assert_not  @a.save, @a.errors.full_messages.inspect
                snd :name, '=', true
    assert      @a.save, @a.errors.full_messages.inspect
  end

  test 'validates_false' do
    create_instance ValidateTest

                snd :name,     '=', true
                snd :password, '=', true
    assert_not  @a.save, @a.errors.full_messages.inspect
                snd :password, '=', false
    assert      @a.save, @a.errors.full_messages.inspect
  end

end

# J-_-L
