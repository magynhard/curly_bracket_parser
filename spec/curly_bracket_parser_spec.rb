require "spec_helper"
require "tempfile"

RSpec.describe CurlyBracketParser do
  it "has a version number" do
    expect(CurlyBracketParser::VERSION).not_to be nil
  end
end

RSpec.describe CurlyBracketParser, '#variables' do
  context 'extract variables from string' do
    it 'parses a set of plain variables without filters' do
      string          = "Today {{one}} person walked {{two  }} times around {{ four_four}}"
      expected_variables = ['{{one}}', '{{two  }}', '{{ four_four}}']
      variables = CurlyBracketParser.variables(string)
      expect(variables).to match_array(expected_variables)
    end
    it 'parses a set of plain variables with filters' do
      string          = "Today {{one |snake_case}} person walked {{two| camel_case}} times around {{four_four  |  word_case}} big {{    cars  | train_case }}"
      expected_variables = ['{{one |snake_case}}', '{{two| camel_case}}', '{{four_four  |  word_case}}', '{{    cars  | train_case }}']
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

RSpec.describe CurlyBracketParser, '#parse_file' do
  context 'plain variable parsing inside a file:' do
    it 'parses a set of plain variables without filters inside a file' do
      variables = {
          one: "one",
          two: "Two",
          three: "FURY"
      }
      source_string = "Today {{one}} person walked {{two}} times around {{three}}"
      tmp_file = Tempfile.new('spec_test_1')
      tmp_file.write source_string
      tmp_file.close
      expected_string = "Today one person walked Two times around FURY"
      parsed = CurlyBracketParser.parse_file(tmp_file.path, variables)
      expect(parsed).to eql(expected_string) # string parsed
      expect(File.read(tmp_file.path)).to eql(source_string) # source file remains unmodified
      tmp_file.unlink
    end
    it 'parses a set of plain variables with spaces before or after name or filter without filters' do
      variables = {
          one: "one",
          two: "Two",
          three: "FURY"
      }
      tmp_file = Tempfile.new('spec_test_2')
      tmp_file.write "Today {{one }} person walked {{  two}} times around {{ three }}"
      tmp_file.close
      expected_string = "Today one person walked Two times around FURY"
      parsed = CurlyBracketParser.parse_file(tmp_file.path, variables)
      expect(parsed).to eql(expected_string)
      tmp_file.unlink
    end
    it 'parses a set of plain variables with filters' do
      variables = {
          one: "one word case",
          two: "TwoPascalCase",
          three: "UPPER-DASH-CASE"
      }
      tmp_file = Tempfile.new('spec_test_3')
      tmp_file.write "Today {{one|dash_case}} person walked {{two|snake_case}} times around {{three|camel_case}}"
      tmp_file.close
      expected_string = "Today one-word-case person walked two_pascal_case times around upperDashCase"
      parsed = CurlyBracketParser.parse_file(tmp_file.path, variables)
      expect(parsed).to eql(expected_string)
      tmp_file.unlink
    end
    it 'parses a set of plain variables with filters, spaces after/before names and filters' do
      variables = {
          one: "one word case",
          two: "TwoPascalCase",
          three: "UPPER-DASH-CASE"
      }
      tmp_file = Tempfile.new('spec_test_4')
      tmp_file.write "Today {{one|   dash_case}} person walked {{two    |   snake_case }} times around {{  three|camel_case  }}"
      tmp_file.close
      expected_string = "Today one-word-case person walked two_pascal_case times around upperDashCase"
      parsed = CurlyBracketParser.parse_file(tmp_file.path, variables)
      expect(parsed).to eql(expected_string)
      tmp_file.unlink
    end
  end
  context 'use options for unresolved variables:' do
    it 'raises an error with one more variable in file' do
      variables = {
          one: "one",
          two: "Two",
          three: "FURY"
      }
      tmp_file = Tempfile.new('spec_test_5')
      tmp_file.write "Today {{one}} person walked {{two}} times around {{three}} {{four}}"
      tmp_file.close
      expect{ CurlyBracketParser.parse_file(tmp_file.path, variables) }.to raise_error(UnresolvedVariablesError)
      tmp_file.unlink
    end
    it 'keeps the variable with one more variable in file' do
      variables = {
          one: "one",
          two: "Two",
          three: "FURY"
      }
      tmp_file = Tempfile.new('spec_test_6')
      tmp_file.write "Today {{one}} person walked {{two}} times around {{three}} {{four}}"
      tmp_file.close
      expected_string = "Today one person walked Two times around FURY {{four}}"
      parsed = CurlyBracketParser.parse_file(tmp_file.path, variables, unresolved_vars: :keep)
      expect(parsed).to eql(expected_string)
      tmp_file.unlink
    end
    it 'replaces the variable with one more variable in file by string' do
      variables = {
          one: "one",
          two: "Two",
          three: "FURY"
      }
      tmp_file = Tempfile.new('spec_test_7')
      tmp_file.write "Today {{one}} person walked {{two}} times around {{three}} {{four}}"
      tmp_file.close
      expected_string = "Today one person walked Two times around FURY "
      parsed = CurlyBracketParser.parse_file(tmp_file.path, variables, unresolved_vars: :replace, replace_pattern: '')
      expect(parsed).to eql(expected_string)
      tmp_file.unlink
    end
    it 'replaces the variable with one more variable in file by pattern with var name' do
      variables = {
          one: "one",
          two: "Two",
          three: "FURY"
      }
      tmp_file = Tempfile.new('spec_test_8')
      tmp_file.write "Today {{one}} person walked {{two}} times around {{three}} {{four}}"
      tmp_file.close
      expected_string = "Today one person walked Two times around FURY ##four##"
      parsed = CurlyBracketParser.parse_file(tmp_file.path, variables, unresolved_vars: :replace, replace_pattern: '##\1##')
      expect(parsed).to eql(expected_string)
      tmp_file.unlink
    end
    it 'replaces the variable with one more variable in file by pattern with filter' do
      variables = {
          one: "one",
          two: "Two",
          three: "FURY"
      }
      tmp_file = Tempfile.new('spec_test_9')
      tmp_file.write "Today {{one}} person walked {{two}} times around {{three}} {{four|filtered}}"
      tmp_file.close
      expected_string = "Today one person walked Two times around FURY ##four:filtered##"
      parsed = CurlyBracketParser.parse_file(tmp_file.path, variables, unresolved_vars: :replace, replace_pattern: '##\1:\2##')
      expect(parsed).to eql(expected_string)
      tmp_file.unlink
    end
  end
end

RSpec.describe CurlyBracketParser, '#parse_file!' do
  context 'plain variable parsing inside a file:' do
    it 'parses a set of plain variables without filters inside a file' do
      variables = {
          one: "one",
          two: "Two",
          three: "FURY"
      }
      tmp_file = Tempfile.new('spec_test_1')
      tmp_file.write "Today {{one}} person walked {{two}} times around {{three}}"
      tmp_file.close
      expected_string = "Today one person walked Two times around FURY"
      parsed = CurlyBracketParser.parse_file!(tmp_file.path, variables)
      expect(parsed).to eql(expected_string)
      expect(File.read(tmp_file.path)).to eql(expected_string)
      tmp_file.unlink
    end
    it 'parses a set of plain variables with spaces before or after name or filter without filters' do
      variables = {
          one: "one",
          two: "Two",
          three: "FURY"
      }
      tmp_file = Tempfile.new('spec_test_2')
      tmp_file.write "Today {{one }} person walked {{  two}} times around {{ three }}"
      tmp_file.close
      expected_string = "Today one person walked Two times around FURY"
      parsed = CurlyBracketParser.parse_file!(tmp_file.path, variables)
      expect(parsed).to eql(expected_string)
      expect(File.read(tmp_file.path)).to eql(expected_string)
      tmp_file.unlink
    end
    it 'parses a set of plain variables with filters' do
      variables = {
          one: "one word case",
          two: "TwoPascalCase",
          three: "UPPER-DASH-CASE"
      }
      tmp_file = Tempfile.new('spec_test_3')
      tmp_file.write "Today {{one|dash_case}} person walked {{two|snake_case}} times around {{three|camel_case}}"
      tmp_file.close
      expected_string = "Today one-word-case person walked two_pascal_case times around upperDashCase"
      parsed = CurlyBracketParser.parse_file!(tmp_file.path, variables)
      expect(parsed).to eql(expected_string)
      expect(File.read(tmp_file.path)).to eql(expected_string)
      tmp_file.unlink
    end
    it 'parses a set of plain variables with filters, spaces after/before names and filters' do
      variables = {
          one: "one word case",
          two: "TwoPascalCase",
          three: "UPPER-DASH-CASE"
      }
      tmp_file = Tempfile.new('spec_test_4')
      tmp_file.write "Today {{one|   dash_case}} person walked {{two    |   snake_case }} times around {{  three|camel_case  }}"
      tmp_file.close
      expected_string = "Today one-word-case person walked two_pascal_case times around upperDashCase"
      parsed = CurlyBracketParser.parse_file!(tmp_file.path, variables)
      expect(parsed).to eql(expected_string)
      expect(File.read(tmp_file.path)).to eql(expected_string)
      tmp_file.unlink
    end
  end
  context 'use options for unresolved variables:' do
    it 'raises an error with one more variable in file' do
      variables = {
          one: "one",
          two: "Two",
          three: "FURY"
      }
      string = "Today {{one}} person walked {{two}} times around {{three}} {{four}}"
      tmp_file = Tempfile.new('spec_test_5')
      tmp_file.write string
      tmp_file.close
      expect{ CurlyBracketParser.parse_file!(tmp_file.path, variables) }.to raise_error(UnresolvedVariablesError)
      expect(File.read(tmp_file.path)).to eql(string)
      tmp_file.unlink
    end
    it 'keeps the variable with one more variable in file' do
      variables = {
          one: "one",
          two: "Two",
          three: "FURY"
      }
      tmp_file = Tempfile.new('spec_test_6')
      tmp_file.write "Today {{one}} person walked {{two}} times around {{three}} {{four}}"
      tmp_file.close
      expected_string = "Today one person walked Two times around FURY {{four}}"
      parsed = CurlyBracketParser.parse_file!(tmp_file.path, variables, unresolved_vars: :keep)
      expect(parsed).to eql(expected_string)
      expect(File.read(tmp_file.path)).to eql(expected_string)
      tmp_file.unlink
    end
    it 'replaces the variable with one more variable in file by string' do
      variables = {
          one: "one",
          two: "Two",
          three: "FURY"
      }
      tmp_file = Tempfile.new('spec_test_7')
      tmp_file.write "Today {{one}} person walked {{two}} times around {{three}} {{four}}"
      tmp_file.close
      expected_string = "Today one person walked Two times around FURY "
      parsed = CurlyBracketParser.parse_file!(tmp_file.path, variables, unresolved_vars: :replace, replace_pattern: '')
      expect(parsed).to eql(expected_string)
      expect(File.read(tmp_file.path)).to eql(expected_string)
      tmp_file.unlink
    end
    it 'replaces the variable with one more variable in file by pattern with var name' do
      variables = {
          one: "one",
          two: "Two",
          three: "FURY"
      }
      tmp_file = Tempfile.new('spec_test_8')
      tmp_file.write "Today {{one}} person walked {{two}} times around {{three}} {{four}}"
      tmp_file.close
      expected_string = "Today one person walked Two times around FURY ##four##"
      parsed = CurlyBracketParser.parse_file!(tmp_file.path, variables, unresolved_vars: :replace, replace_pattern: '##\1##')
      expect(parsed).to eql(expected_string)
      expect(File.read(tmp_file.path)).to eql(expected_string)
      tmp_file.unlink
    end
    it 'replaces the variable with one more variable in file by pattern with filter' do
      variables = {
          one: "one",
          two: "Two",
          three: "FURY"
      }
      tmp_file = Tempfile.new('spec_test_9')
      tmp_file.write "Today {{one}} person walked {{two}} times around {{three}} {{four|filtered}}"
      tmp_file.close
      expected_string = "Today one person walked Two times around FURY ##four:filtered##"
      parsed = CurlyBracketParser.parse_file!(tmp_file.path, variables, unresolved_vars: :replace, replace_pattern: '##\1:\2##')
      expect(parsed).to eql(expected_string)
      expect(File.read(tmp_file.path)).to eql(expected_string)
      tmp_file.unlink
    end
  end
end

RSpec.describe CurlyBracketParser, '#register_filter' do
  context 'register and use custom filters' do
    it 'includes a registered filter after registration' do
      filter_name = 'my_one'
      CurlyBracketParser.register_filter filter_name do |string|
        string
      end
      expect(CurlyBracketParser.valid_filters).to include(filter_name)
    end
    it 'can not register/overwrite a default filter' do
      expect {
        filter_name = 'snake_case'
        CurlyBracketParser.register_filter filter_name do |string|
          string
        end
      }.to raise_error(FilterAlreadyRegisteredError)
    end
    it 'can not register/overwrite a new registered filter' do
      filter_name = 'my_second'
      CurlyBracketParser.register_filter filter_name do |string|
        string
      end
      expect {
        CurlyBracketParser.register_filter filter_name do |string|
          string
        end
      }.to raise_error(FilterAlreadyRegisteredError)
    end
    it 'can use a registered filter #1' do
      filter_name = 'duplicate'
      CurlyBracketParser.register_filter filter_name do |string|
        string.to_s + string.to_s
      end
      expect(CurlyBracketParser.process_filter(filter_name,"hooray")).to eql("hoorayhooray")
    end
    it 'can use a registered filter #2' do
      filter_name = 'snake_cake'
      CurlyBracketParser.register_filter filter_name do |string|
        LuckyCase.snake_case string
      end
      expect(CurlyBracketParser.process_filter(filter_name,"TheSaladTastesSour")).to eql("the_salad_tastes_sour")
    end
  end
end

RSpec.describe CurlyBracketParser, '#register_default_var' do
  context 'register and use default variables' do
    it 'includes a registered variable automatically after registration' do
      variable_name = 'my_default1'
      variable_value = 'MySuperValue1'
      CurlyBracketParser.register_default_var variable_name do
        variable_value
      end
      expect(CurlyBracketParser.registered_default_vars).to include(variable_name)
    end
    it 'includes a registered variable automatically after registration #2' do
      variable_name = 'my_default11'
      variable_value = 'MySuperValue11'
      CurlyBracketParser.register_default_var variable_name do
        variable_value
      end
      expect(CurlyBracketParser.registered_default_var?(variable_name)).to eql(true)
    end
    it 'can not register/overwrite a existing registered variable' do
      variable_name = 'my_default2'
      variable_value = 'MySuperValue2'
      CurlyBracketParser.register_default_var variable_name do
        variable_value
      end
      expect {
        CurlyBracketParser.register_default_var variable_name do
          variable_value
        end
      }.to raise_error(VariableAlreadyRegisteredError)
    end
    it 'can process default variable' do
      variable_name = 'my_default7'
      variable_value = 'MySuperValue7'
      CurlyBracketParser.register_default_var variable_name do
        variable_value
      end
      expect(CurlyBracketParser.process_default_var(variable_name)).to eql(variable_value)
    end
    it 'can use a registered default value #1' do
      variable_name = 'my_default3'
      variable_value = 'MySuperValue3'
      CurlyBracketParser.register_default_var variable_name do
        variable_value
      end
      expect(CurlyBracketParser.parse("Some{{#{variable_name}}}Good", nil)).to eql("Some#{variable_value}Good")
    end
    it 'can overwrite a registered default value by parameter' do
      variable_name = 'my_default9'
      variable_value = 'MySuperValue9'
      CurlyBracketParser.register_default_var variable_name do
        variable_value
      end
      expect(CurlyBracketParser.parse("Some{{#{variable_name}}}Good", { my_default9: 'Overwritten'})).to eql("SomeOverwrittenGood")
    end
    it 'can overwrite a registered default value by function' do
      variable_name = 'my_default22'
      variable_value = 'MySuperValue22'
      variable_overwrite_value = 'MySuperValue77'
      CurlyBracketParser.register_default_var variable_name do
        variable_value
      end
      CurlyBracketParser.register_default_var! variable_name do
        variable_overwrite_value
      end
      expect(CurlyBracketParser.parse("Some{{#{variable_name}}}Good", { my_default9: 'Overwritten'})).to eql("Some#{variable_overwrite_value}Good")
    end
  end
end

RSpec.describe CurlyBracketParser, '#unregister_default_var' do
  context 'unregister default variables' do
    it 'registers and unregistereds a default variable' do
      variable_name = 'my_default_un'
      variable_value = 'MySuperValueUn'
      CurlyBracketParser.register_default_var variable_name do
        variable_value
      end
      expect(CurlyBracketParser.registered_default_vars).to include(variable_name)
      CurlyBracketParser.unregister_default_var variable_name
      expect(CurlyBracketParser.registered_default_vars).not_to include(variable_name)
    end
  end
end

RSpec.describe CurlyBracketParser, '#decoded_variables' do
  context 'decode a string and get its variables' do
    it 'decode string with several variables, with and without filters' do
      string = 'This is my {{var1}} super string, containing {{count|filter_some}} variables and a lot of {{fun}}'
      decoded_variables = CurlyBracketParser.decoded_variables string
      expect(decoded_variables.map{|e| e[:name] }.flatten).to match_array(%w[ var1 count fun ])
      expect(decoded_variables.map{|e| e[:filter] }.flatten).to match_array([nil, 'filter_some', nil])
    end
  end
end

RSpec.describe CurlyBracketParser, '#includes_one_variable_of' do
  context 'includes one of the given variables in the given string' do
    it 'includes all of the three variables' do
      string = 'This is my {{var2}} super string, containing {{count2|filter_some}} variables and a lot of {{fun3}}'
      expect(CurlyBracketParser.includes_one_variable_of(['var2','count2','fun3'], string)).to eql(true)
      expect(CurlyBracketParser.includes_one_variable_of(['var','count','fun'], string)).to eql(false)
      expect(CurlyBracketParser.includes_one_variable_of(['var2'], string)).to eql(true)
      expect(CurlyBracketParser.includes_one_variable_of(['count2'], string)).to eql(true)
      expect(CurlyBracketParser.includes_one_variable_of(['fun3'], string)).to eql(true)
    end
  end
end