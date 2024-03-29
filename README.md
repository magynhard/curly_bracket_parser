# curly_bracket_parser
[![Gem](https://img.shields.io/gem/v/curly_bracket_parser?color=default&style=plastic&logo=ruby&logoColor=red)](https://rubygems.org/gems/curly_bracket_parser)
![downloads](https://img.shields.io/gem/dt/curly_bracket_parser?color=blue&style=plastic)
[![License: MIT](https://img.shields.io/badge/License-MIT-gold.svg?style=plastic&logo=mit)](LICENSE)

> Ruby gem providing a simple parser to replace curly brackets `{{like_this}}` inside strings like URLs, texts or even files easily.

Additional support for build-in filters and custom filters make them more powerful. `{{example|my_filter}}`

Using [LuckyCase](https://github.com/magynhard/lucky_case), all its case formats are supported as filter by default.





# Contents

* [Installation](#installation)
* [Usage examples](#usage)
* [Documentation](#documentation)
* [Contributing](#contributing)




<a name="installation"></a>
## Installation

Add this line to your application's Gemfile:

```ruby
gem 'curly_bracket_parser'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install curly_bracket_parser
    

<a name="usage"></a>
## Usage examples

You can either parse variables inside strings or even directly in files.

### Basic

```ruby
    url = "https://my-domain.com/items/{{item_id}}"
    final_url = CurlyBracketParser.parse url, { item_id: 123 }
    # => "https://my-domain.com/items/123"
```

Nested variables are supported as well:
```ruby
    tmpl = "This is my template with {{my_nested_variable}}";
    my_nested_variable = "my {{nested}} variable"; 
    parsed_tmpl = CurlyBracketParser.parse tmpl, { my_nested_variable: my_nested_variable, nested: 'pizza'}
    # => "This is my template with my pizza variable"
```



### Filters

```ruby
    url = "https://my-domain.com/catalog/{{item_name|snake_case}}"
    final_url = CurlyBracketParser.parse url, { item_name: 'MegaSuperItem' }
    # => "https://my-domain.com/catalog/mega_super_item"
```

For a list of built-in filters visit [LuckyCase](https://github.com/magynhard/lucky_case).

#### Define your custom filter

```ruby
    CurlyBracketParser.register_filter('7times') do |string|
      string.to_s * 7
    end

    text = "Paul went out and screamed: A{{scream|7times}}h"
    final_text = CurlyBracketParser.parse text, { scream: 'a' }
    # => "Paul went out and screamed: Aaaaaaaah"
```


### Value variables

For special cases you can directly define or set variables inside the template - usually it does only make sense, if you combine them with custom filters.

You can either use quotes to define a string or numbers (integer or floating point) directly.

Empty values are possible as well. They are equal to a empty string.

```ruby
    tmpl = %Q(This is a {{'string'|pascal_case}} and today is {{"today"|date_filter}}. Peter is {{'1990-10-05'|iso_date_age}} years old. His girlfriends name is {{girl|pascal_case}} and she is {{16|double_number}} years old. This article has been written at {{|date_now_formatted}}`)
    parsed = CurlyBracketParser.parse tmpl, { girl: "anna" }
    # => "This is a String and today is 2022-06-27. Peter is 32 years old. His girlfriends name is Anna and she is 32 years old. This article has been written at 6/28/2022, 12:46:40 PM."
```


### Files

<ins>test.html</ins>
```html
<h1>{{title|sentence_case}}</h1>
```

```ruby
    parsed_file = CurlyBracketParser.parse_file './test.html', { title: 'WelcomeAtHome' }
    # => "<h1>Welcome at home</h1>"
```

Use `#parse_file!` instead to write the parsed string directly into the file!

### Default variables

You can define default variables, which will be replaced automatically without passing them by parameters, but can be overwritten with parameters.

Because of providing blocks, your variables can dynamically depend on other states (e.g. current date).

```ruby
    CurlyBracketParser.register_default_var('version') do
      '1.0.2'
    end

    text = "You are running version {{version}}"
    CurlyBracketParser.parse text
    # => "You are running version 1.0.2"
    CurlyBracketParser.parse text, { version: '0.7.0' }
    # => "You are running version 0.7.0"
```




<a name="documentation"></a>
## Documentation
Check out the doc at RubyDoc
<a href="https://www.rubydoc.info/gems/curly_bracket_parser">https://www.rubydoc.info/gems/curly_bracket_parser</a>





<a name="contributing"></a>
## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/magynhard/curly_bracket_parser. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

