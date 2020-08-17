require 'lucky_case'

require 'curly_bracket_parser/version'
require_relative 'custom_errors/unresolved_variables_error'

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

  VALID_FILTERS = [
      LuckyCase::CASES.keys.map(&:to_s)
  ].flatten

  #----------------------------------------------------------------------------------------------------

  # @param [String] string to parse
  # @param [Hash<Symbol => String>] variables <key: 'value'>
  # @param [Symbol] unresolved_vars :raise, :keep, :replace => define how to act when unresolved variables within the string are found.
  # @param [String] replace_pattern pattern used when param unresolved_vars is set to :replace. You can include the var name \\1 and filter \\1. Empty string to remove unresolved variables.
  # @return [String, UnresolvedVariablesError] parsed string
  def self.parse(string, variables, unresolved_vars: :raise, replace_pattern: "##\\1##")
    result_string = string.clone
    if CurlyBracketParser.any_variable_included? string
      loop do
        variables(string).each do |string_var|
          name, filter = decode_variable(string_var)
          if variables[name.to_sym]
            value = process_filter(variables[name.to_sym], filter)
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

  def self.parse_file(path, variables, options = {})
    raise "NOT IMPLEMENTED YET!"
  end

  def self.parse_file!(path, variables, options = {})
    raise "NOT IMPLEMENTED YET!"
  end

  #----------------------------------------------------------------------------------------------------

  def self.register_filter(name, function)
    raise "NOT IMPLEMENTED YET!"
  end

  #----------------------------------------------------------------------------------------------------

  def self.register_default_variable(name, function)
    raise "NOT IMPLEMENTED YET!"
  end

  #----------------------------------------------------------------------------------------------------

  def self.process_filter(value, filter)
    return value unless filter
    if VALID_FILTERS.include? filter
      if LuckyCase.valid_case_type? filter
        return LuckyCase.convert_case(value, filter)
      else
        raise "FILTER '#{filter}' NOT IMPLEMENTED YET!"
      end
    else
      raise "Invalid filter '#{filter}'"
    end
  end

  #----------------------------------------------------------------------------------------------------

  def self.has_filter?(variable)
    decode_variable(variable)[:filter] != nil
  end

  #----------------------------------------------------------------------------------------------------

  # Return a hash containing separated name and filter of a variable
  #
  # @example
  #   '{{var_name|filter_name}}' => { name: 'var_name', filter: 'filter_name' }
  #
  # @param [String] variable
  # @return [Array(String, String)] name, filter
  def self.decode_variable(variable)
    var = decoded_variables(variable).first
    [var.keys.first, var.values.first]
  end

  #----------------------------------------------------------------------------------------------------

  # scans the given url for variables with pattern '{{var}}'
  # @param [String] string to scan
  # @return [Array<Hash<Symbol => String>>] array of variable names and its filters
  def self.decoded_variables(string)
    var_name = 0
    var_filter = 1
    string.scan(VARIABLE_DECODER_REGEX).map { |e| {"#{e[var_name].strip}": e[var_filter].strip != '' ? e[var_filter].strip : nil } }.flatten
  end

  #----------------------------------------------------------------------------------------------------

  # scans the given url for variables with pattern '{{var}}'
  # @param [String] string to scan
  # @return [Array<String>] array of variable names and its filters
  def self.variables(string)
    string.scan(VARIABLE_REGEX).flatten
  end

  #----------------------------------------------------------------------------------------------------

  def self.any_variable_included?(string)
    string.match(VARIABLE_REGEX) != nil
  end

  #----------------------------------------------------------------------------------------------------

  def self.includes_one_variable_of(variable_names, string)
    decoded_variables(string).each do |dvar|
      return true if variable_names.include?(dvar[:name])
    end
    false
  end

  #----------------------------------------------------------------------------------------------------

end
