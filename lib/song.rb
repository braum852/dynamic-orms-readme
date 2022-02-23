require_relative "../config/environment.rb"
require 'active_support/inflector'
##Allows pluralise to be use

class Song


  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')"
    ##How do you query a table for the names of its columns? For this we need to use the above SQL query

    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      column_names << row["name"] ##We iterate over the resulting array of hashes to collect just the name of each column
    end
    column_names.compact ##We call #compact on that just to be safe and get rid of any nil values that may end up in our collection.
  end

  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
  end
  ##Here, we iterate over the column names stored in the column_names class method and set an attr_accessor for each one, 
  #making sure to convert the column name string into a symbol with the #to_sym method, since attr_accessors must be named with symbols.
  #This is ergo metaprogramming, because we are writing code that writes code for us. 
  #By setting the attr_accessors in this way, a reader and writer method for each column name is dynamically created, 
  #without us ever having to explicitly name each of these methods.

  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end
  #Here, we define our method to take in an argument of options, which defaults to an empty hash. 
  #We expect #new to be called with a hash, so when we refer to options inside the #initialize method, we expect to be operating on a hash.
  #We iterate over the options hash and use our fancy metaprogramming #send method to interpolate the name of each hash key as a method that we set equal to that key's value. 
  #As long as each property has a corresponding attr_accessor, this #initialize method will work.

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert
    self.class.table_name
  end
  #Recall, however, that the conventional #save is an instance method. 
  #So, inside a #save method, self will refer to the instance of the class, not the class itself. 
  #In order to use a class method inside an instance method, we need to do the following:

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    #to remove "id" from the array of column names returned from the method call
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end



