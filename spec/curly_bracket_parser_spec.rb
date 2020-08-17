require "spec_helper"

RSpec.describe CurlyBracketParser do
  it "has a version number" do
    expect(CurlyBracketParser::VERSION).not_to be nil
  end
end

RSpec.describe CurlyBracketParser, '#variables' do
  context 'extract variables from string' do

    it 'parses a set of plain variables without filters' do
      string          = "Today {{one}} person walked {{two}} times around {{four_four}}"
      expected_variables = %w[{{one}} {{two}} {{four_four}}]
      variables = CurlyBracketParser.variables(string)
      expect(variables).to match_array(expected_variables)
    end

  end
end

RSpec.describe CurlyBracketParser, '#parse' do
  context 'plain variable parsing' do
    it 'parses a set of plain variables without filters' do
      variables = {
          one: "one",
          two: "Two",
          three: "FURY"
      }
      string          = "Today {{one}} person walked {{two}} times around {{three}}"
      expected_string = "Today one person walked Two times around FURY"
      parsed = CurlyBracketParser.parse(string, variables)
      expect(parsed).to eql(expected_string)
    end
    it 'parses a set of plain variables with spaces before or after name or filter without filters' do
      variables = {
          one: "one",
          two: "Two",
          three: "FURY"
      }
      string          = "Today {{one }} person walked {{  two}} times around {{ three }}"
      expected_string = "Today one person walked Two times around FURY"
      parsed = CurlyBracketParser.parse(string, variables)
      expect(parsed).to eql(expected_string)
    end
    it 'parses a set of plain variables with filters' do
      variables = {
          one: "one word case",
          two: "TwoPascalCase",
          three: "UPPER-DASH-CASE"
      }
      string          = "Today {{one|dash_case}} person walked {{two|snake_case}} times around {{three|camel_case}}"
      expected_string = "Today one-word-case person walked two_pascal_case times around upperDashCase"
      parsed = CurlyBracketParser.parse(string, variables)
      expect(parsed).to eql(expected_string)
    end
    it 'parses a set of plain variables with filters, spaces after/before names and filters' do
      variables = {
          one: "one word case",
          two: "TwoPascalCase",
          three: "UPPER-DASH-CASE"
      }
      string          = "Today {{one|   dash_case}} person walked {{two    |   snake_case }} times around {{  three|camel_case  }}"
      expected_string = "Today one-word-case person walked two_pascal_case times around upperDashCase"
      parsed = CurlyBracketParser.parse(string, variables)
      expect(parsed).to eql(expected_string)
    end
  end
  context 'use options for unresolved variables' do
    it 'raises an error with one more variable in string' do
      variables = {
          one: "one",
          two: "Two",
          three: "FURY"
      }
      string          = "Today {{one}} person walked {{two}} times around {{three}} {{four}}"
      expect{ CurlyBracketParser.parse(string, variables) }.to raise_error(UnresolvedVariablesError)
    end
    it 'keeps the variable with one more variable in string' do
      variables = {
          one: "one",
          two: "Two",
          three: "FURY"
      }
      string          = "Today {{one}} person walked {{two}} times around {{three}} {{four}}"
      expected_string = "Today one person walked Two times around FURY {{four}}"
      parsed = CurlyBracketParser.parse(string, variables, unresolved_vars: :keep)
      expect(parsed).to eql(expected_string)
    end
    it 'replaces the variable with one more variable in string by string' do
      variables = {
          one: "one",
          two: "Two",
          three: "FURY"
      }
      string          = "Today {{one}} person walked {{two}} times around {{three}} {{four}}"
      expected_string = "Today one person walked Two times around FURY "
      parsed = CurlyBracketParser.parse(string, variables, unresolved_vars: :replace, replace_pattern: '')
      expect(parsed).to eql(expected_string)
    end
    it 'replaces the variable with one more variable in string by pattern with var name' do
      variables = {
          one: "one",
          two: "Two",
          three: "FURY"
      }
      string          = "Today {{one}} person walked {{two}} times around {{three}} {{four}}"
      expected_string = "Today one person walked Two times around FURY ##four##"
      parsed = CurlyBracketParser.parse(string, variables, unresolved_vars: :replace, replace_pattern: '##\1##')
      expect(parsed).to eql(expected_string)
    end
    it 'replaces the variable with one more variable in string by pattern with filter' do
      variables = {
          one: "one",
          two: "Two",
          three: "FURY"
      }
      string          = "Today {{one}} person walked {{two}} times around {{three}} {{four|filtered}}"
      expected_string = "Today one person walked Two times around FURY ##four:filtered##"
      parsed = CurlyBracketParser.parse(string, variables, unresolved_vars: :replace, replace_pattern: '##\1:\2##')
      expect(parsed).to eql(expected_string)
    end
  end
end