ActiveRecord::Schema.define(:version => 0) do
  %w|
   appends
   append_nils
   defaults
   many_options
   no_options
   hmbs
   suffix_nones
   suffix_question_onlies
   suffix_equal_onlies
   suffix_exclamation_onlies
   selves
   self_append_nils
   self_names
   ar_callbacks
   lazy_falses
   booleans_as_hashes
   single_hashes
   validate_tests
   false_values
   scopes
  |.each do |table_name|
    create_table table_name, :force => true do |t|
      t.string :name
      t.integer :booleans
    end
  end

  create_table 'fields', :force => true do |t|
    t.string :name
    t.integer :bools
  end

end

