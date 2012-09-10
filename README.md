# mongoid-ordering  [![Build Status](https://secure.travis-ci.org/DouweM/mongoid-ordering.png?branch=master)](http://travis-ci.org/DouweM/mongoid-ordering)

mongoid-ordering makes it easy to keep your Mongoid documents in order.

Most of mongoid-ordering is based on the 
`Mongoid::Tree::Ordering` module from the
[mongoid-tree](https://github.com/benedikt/mongoid-tree) gem. I thought
the ordering logic would be useful outside of the tree context as well, so I 
extracted it into the gem you're looking at right now.

## Features

* Automatically order your query results by a new `position` attribute.
* Allow documents to be ordered within a certain scope.
* Handle changes in position when a document is destroyed or when a document is 
  moved outside of this scope.
* Tons of utility methods to make working with ordered documents incredibly easy.

## Requirements

* mongoid (~> 3.0)

## Installation

Add the following to your Gemfile:

```ruby
gem "mongoid-ordering", require: "mongoid/ordering"
```

And tell Bundler to install the new gem:

```
bundle install
```

## Usage

Include the `Mongoid::Ordering` module in your document class:

```ruby
class Book
  include Mongoid::Document
  include Mongoid::Ordering

  ...
end
```

This will take care of everything to get you going. 

If you want to specify a scope within which to keep the documents in order, 
you can like this:

```ruby
class Book
  include Mongoid::Document
  include Mongoid::Ordering

  belongs_to :author

  ordered scope: :author

  ...
end
```

You will now have access to the following methods:

```ruby
# Retrieve siblings positioned above this document.
book.higher_siblings
# Retrieve siblings positioned below this document.
book.lower_siblings
# Retrieve the highest sibling.
book.highest_sibling
# Retrieve the lowest sibling.
book.lowest_sibling

# Is this the highest sibling?
book.at_top?
# Is this the lowest sibling?
book.at_bottom?

# Move document to the top.
book.move_to_top
# Move document to the bottom.
book.move_to_bottom
# Move document one position up.
book.move_up
# Move document one position down.
book.move_down
# Move document above another document.
book.move_above(other_book)
# Move document below another document.
book.move_below(other_book)
```

mongoid-ordering uses [mongoid-siblings](https://github.com/DouweM/mongoid-siblings) to get all of this to work, so you'll get the following methods as a bonus:

```ruby
# Retrieve document's siblings
book.siblings
# Retrieve document's siblings and itself
book.siblings_and_self
# Is this document a sibling of the other document?
book.sibling_of?(other_book)
# Make document a sibling of the other document.
# This will move this book to the same scope as the other book.
book.sibling_of!(other_book)
```

## Full documentation
See [this project's RubyDoc.info page](http://rubydoc.info/github/DouweM/mongoid-ordering/master/frames).

## Known issues
See [the GitHub Issues page](https://github.com/DouweM/mongoid-ordering/issues).

## License
Copyright (c) 2012 Douwe Maan

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.