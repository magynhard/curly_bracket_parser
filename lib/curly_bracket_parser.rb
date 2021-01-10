require 'lucky_case'

require 'curly_bracket_parser/version'
require_relative 'custom_errors/filter_already_registered_error'
require_relative 'custom_errors/invalid_filter_error'
require_relative 'custom_errors/invalid_variable_error'
require_relative 'custom_errors/unresolved_variables_error'
require_relative 'custom_errors/variable_already_registered_error'

#
# CurlyBracketParser
#
# Parse variables with curly brackets within templates/strings or files
#
# Use filters for special cases
#

module CurlyBracketParser

  # {{variable_name|optional_filter}}
  VARIABLE_DECODER_REGEX = /{{([^{}\|]+)\|?([^{}\|]*)}}/
  VARIABLE_REGEX = /{{[^{}]+}}/

  VALID_DEFAULT_FILTERS = [
    LuckyCase::CASES.keys.map(&:to_s)
  ].flatten

  #----------------------------------------------------------------------------------------------------

  # Parse given string and replace the included variables by the given variables
  #
  # @param [String] string to parse
  # @param [Hash<Symbol => String>] variables <key: 'value'>
  # @param [Symbol] unresolved_vars :raise, :keep, :replace => define how to act when unresolved variables within the string are found.
  # @param [String] replace_pattern pattern used when param unresolved_vars is set to :replace. You can include the var name \\1 and filter \\2. Empty string to remove unresolved variables.
  # @return [String, UnresolvedVariablesError] parsed string
  def self.parse(string, variables, unresolved_vars: :raise, replace_pattern: "##\\1##")
    variables ||= {}
    result_string = string.clone
    if CurlyBracketParser.any_variable_included? string
      loop do
        variables(string).each do |string_var|
          dec = decode_variable(string_var)
          name = dec[:name]
          filter = dec[:filter]
          if variables[name.to_sym]
            value = if filter
                      process_filter(filter, variables[name.to_sym])
                    else
                      variables[name.to_sym]
                    end
            result_string.gsub!(string_var, value)
          elsif registered_default_var?(name.to_s)
            value = process_default_var(name)
            result_string.gsub!(string_var, value)
          end
        end
        # break if no more given variable is available
        break unless any_variable_included?(string) && includes_one_variable_of(variables, string)
      end
      case unresolved_vars
      when :raise
        if any_variable_included? result_string
          raise UnresolvedVariablesError, "There are unresolved variables in the given string: #{variables(result_string)}"
        end
      when :replace
        result_string.gsub!(VARIABLE_DECODER_REGEX, replace_pattern)
      end
    end
    result_string
  end

  #----------------------------------------------------------------------------------------------------

  # Parse the content of the file of the given path with #parse and return it.
  # The original file keeps unmodified.
  #
  # @param [String] string to parse
  # @param [Hash<Symbol => String>] variables <key: 'value'>
  # @param [Symbol] unresolved_vars :raise, :keep, :replace => define how to act when unresolved variables within the string are found.
  # @param [String] replace_pattern pattern used when param unresolved_vars is set to :replace. You can include the var name \\1 and filter \\1. Empty string to remove unresolved variables.
  # @return [String, UnresolvedVariablesError] parsed string
  def self.parse_file(path, variables, unresolved_vars: :raise, replace_pattern: "##\\1##")
    file_content = File.read path
    parse(file_content, variables, unresolved_vars: unresolved_vars, replace_pattern: replace_pattern)
  end

  # Parse the content of the file of the given path with #parse and return it.
  # The original file will be overwritten by the parsed content.
  #
  # @param [String] string to parse
  # @param [Hash<Symbol => String>] variables <key: 'value'>
  # @param [Symbol] unresolved_vars :raise, :keep, :replace => define how to act when unresolved variables within the string are found.
  # @param [String] replace_pattern pattern used when param unresolved_vars is set to :replace. You can include the var name \\1 and filter \\1. Empty string to remove unresolved variables.
  # @return [String, UnresolvedVariablesError] parsed string
  def self.parse_file!(path, variables, unresolved_vars: :raise, replace_pattern: "##\\1##")
    parsed_file = parse_file path, variables, unresolved_vars: unresolved_vars, replace_pattern: replace_pattern
    File.write path, parsed_file
    parsed_file
  end

  #----------------------------------------------------------------------------------------------------

  # Register your custom filter to the filter list
  #
  # @param [String] filter name of the filter, also used then in your strings, e.g. {{var_name|my_filter_name}}
  # @param [Lambda] function of the filter to run the variable against
  # @raise [FilterAlreadyRegisteredError] if filter does already exist
  # @return [Proc] given block
  def self.register_filter(filter, &block)
    @@registered_filters ||= {}
    filter = filter.to_s
    if valid_filter?(filter)
      raise FilterAlreadyRegisteredError, "The given filter name '#{filter}' is already registered"
    else
      @@registered_filters[filter] = block
    end
  end

  #----------------------------------------------------------------------------------------------------

  # Process the given value with the given filter
  #
  # @param [String] filter name of the filter, also used then in your strings, e.g. {{var_name|my_filter_name}}
  # @param [String] value string to apply the specified filter on
  # @return [String] converted string with applied filter
  def self.process_filter(filter, value)
    @@registered_filters ||= {}
    filter = filter.to_s
    if @@registered_filters[filter]
      @@registered_filters[filter].call(value)
    elsif VALID_DEFAULT_FILTERS.include?(filter) && LuckyCase.valid_case_type?(filter)
      LuckyCase.convert_case(value, filter)
    else
      message = "Invalid filter '#{filter}'. Valid filters are: #{self.valid_filters.join(' ')}"
      raise InvalidFilterError, message
    end
  end

  #----------------------------------------------------------------------------------------------------

  # Retrieve Array with valid filters
  #
  # @return [Array<String>] of valid filters
  def self.valid_filters
    all_filters = VALID_DEFAULT_FILTERS
    @@registered_filters ||= {}
    all_filters + @@registered_filters.keys.map(&:to_s)
  end

  #----------------------------------------------------------------------------------------------------

  # Check if a given filter is valid
  #
  # @param [String] name
  # @return [Boolean] true if filter exists, otherwise false
  def self.valid_filter?(name)
    self.valid_filters.include? name
  end

  #----------------------------------------------------------------------------------------------------

  # Register a default variable to be replaced automatically by the given block value in future
  # If the variable exists already, it will raise an VariableAlreadyRegisteredError
  #
  # @param [String] name of the default var
  # @param [Proc] block
  # @raise [VariableAlreadyRegisteredError] if variable is already registered
  # @return [Proc] given block
  def self.register_default_var(name, &block)
    @@registered_default_vars ||= {}
    name = name.to_s
    if registered_default_var?(name)
      raise VariableAlreadyRegisteredError, "The given variable name '#{name}' is already registered. If you want to override that variable explicitly, call #register_default_var! instead!"
    else
      @@registered_default_vars[name] = block
    end
  end

  #----------------------------------------------------------------------------------------------------

  # Return the given default variable by returning the result of its block/proc
  #
  # @param [String] name of the variable to return
  # @return [String] value of the variable
  def self.process_default_var(name)
    @@registered_default_vars ||= {}
    name = name.to_s
    if @@registered_default_vars[name]
      @@registered_default_vars[name].call()
    else
      message = "Invalid default variable '#{name}'. Valid registered default variables are: #{self.registered_default_vars.keys.join(' ')}"
      raise InvalidVariableError, message
    end
  end

  #----------------------------------------------------------------------------------------------------

  # Register a default variable to be replaced automatically by the given block value in future
  # If the variable exists already, it will be overwritten
  #
  # @param [String] name of the default var
  # @param [Proc] block
  # @raise [VariableAlreadyRegisteredError] if variable is already registered
  # @return [Proc] given block
  def self.register_default_var!(name, &block)
    @@registered_default_vars ||= {}
    name = name.to_s
    @@registered_default_vars[name] = block
  end

  #----------------------------------------------------------------------------------------------------

  # Unregister / remove an existing default variable
  #
  # @param [String] name of the variable
  # @return [Boolean] true if variable existed and was unregistered, false if it didn't exist
  def self.unregister_default_var(name)
    @@registered_default_vars ||= {}
    name = name.to_s
    if @@registered_default_vars[name]
      @@registered_default_vars.delete(name)
      true
    else
      false
    end
  end

  #----------------------------------------------------------------------------------------------------

  # Return an array of registered default variables
  #
  # @return [Array<String>]
  def self.registered_default_vars
    @@registered_default_vars ||= {}
    @@registered_default_vars.keys.map(&:to_s)
  end

  #----------------------------------------------------------------------------------------------------

  # Check if the given variable is a registered default variable
  #
  # @param [String] name of the variable
  # @return [Boolean] true if variable is registered, otherwise false
  def self.registered_default_var?(name)
    self.registered_default_vars.include? name
  end

  #----------------------------------------------------------------------------------------------------

  # Return a hash containing separated name and filter of a variable
  #
  # @example
  #   '{{var_name|filter_name}}' => { name: 'var_name', filter: 'filter_name' }
  #
  # @param [String] variable
  # @return [Hash<String => String>] name, filter
  def self.decode_variable(variable)
    decoded_variables(variable).first
  end

  #----------------------------------------------------------------------------------------------------

  # Scans the given url for variables with pattern '{{var|optional_filter}}'
  #
  # @example
  #   'The variable {{my_var|my_filter}} is inside this string' => [{ name: "my_var", filter: "my_filter"}]
  #
  # @param [String] string to scan
  # @return [Array<Hash<Symbol => String>>] array of variable names and its filters
  def self.decoded_variables(string)
    var_name_index = 0
    var_filter_index = 1
    string.scan(VARIABLE_DECODER_REGEX).map { |e| { name: "#{e[var_name_index].strip}", filter: e[var_filter_index].strip != '' ? e[var_filter_index].strip : nil } }.flatten
  end

  #----------------------------------------------------------------------------------------------------

  # Scans the given url for variables with pattern '{{var|optional_filter}}'
  #
  # @param [String] string to scan
  # @return [Array<String>] array of variable names and its filters
  def self.variables(string)
    string.scan(VARIABLE_REGEX).flatten
  end

  #----------------------------------------------------------------------------------------------------

  # Check if any variable is included in the given string
  #
  # @param [String] string name of variable to check for
  # @return [Boolean] true if any variable is included in the given string, otherwise false
  def self.any_variable_included?(string)
    string.match(VARIABLE_REGEX) != nil
  end

  #----------------------------------------------------------------------------------------------------

  # Check if one of the given variable names is included in the given string
  #
  # @param [Array<String>] variable_names
  # @param [String] string name of variable to check for
  # @return [Boolean] true if one given variable name is included in given the string, otherwise false
  def self.includes_one_variable_of(variable_names, string)
    decoded_variables(string).each do |dvar|
      return true if variable_names.include?(dvar[:name])
    end
    false
  end

  #----------------------------------------------------------------------------------------------------

end
