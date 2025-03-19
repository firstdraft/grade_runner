# grade_runner

A Ruby client for [firstdraft Grades](https://grades.firstdraft.com)


## Installation

Add this line to your application's Gemfile:

```ruby
gem "grade_runner"
```

And then execute:
```bash
$ bundle
```

## Usage

### Rails

After installed, run `rails grade` to run specs.

#### Optional Configuration

As of version 0.0.13, you can override the default points used on each test and the overwriting behavior of the spec folder by:

Moving the gem into the `:development, :test` group in your Gemfile:

```ruby
# Gemfile

# ...
group :development, :test do
  gem "grade_runner", "~> 0.0.13"
  # ...
end
# ...
```

Adding this configurable initializer:

```rb
# config/initializers/grade_runner.rb

if Rails.env.development? || Rails.env.test?
  GradeRunner.config do |config|
    config.default_points = 1           # default 1
    config.override_local_specs = false # default true
  end
end
```

Adding this line to the `Rakefile`:

```rb
# Rakefile

require_relative "config/initializers/grade_runner"
```

And making this change to the `spec_helper.rb`:

```rb
# spec/spec_helper.rb

# ...

# GradeRunner updates on https://github.com/firstdraft/grade_runner/pull/88
# make the formatters available from within the grade_runner gem
require "grade_runner/formatters/json_output_formatter"
require "grade_runner/formatters/hint_formatter"
# require "#{File.expand_path("../support/json_output_formatter", __FILE__)}"
# require "#{File.expand_path("../support/hint_formatter", __FILE__)}"

# ...
```

Note that for that last step, the gem formatters can be overridden by requiring the formatters present in the local project like before.

### Ruby

In order to load and run the Rake task, you need to load it.

This is usually done by making a runnable file[^1], typically called `bin/rails`, with contents that look like this:

```rb
#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
require "rake"

dir = Gem::Specification.find_by_name("grade_runner").gem_dir

load "#{dir}/lib/tasks/grade.rake"
task_name = ARGV[0]

Rake::Task[task_name].invoke
```

Then you can run `bin/rails grade` like before. You can even add this file to the `PATH` so you can run `rails grade` like with Rails apps.

```bash
echo 'export PATH="$PATH:/path/to/project/bin/rails"' >> ~/.bashrc
source ~/.bashrc
```

---

[^1]: If you get file permissions errors when running `bin/rails grade` try updating the permissions with `chmod 755 bin/rails` first.

Copyright
---------

Copyright (c) 2018 Raghu Betina. See [LICENSE.txt](LICENSE.txt) for further details.
