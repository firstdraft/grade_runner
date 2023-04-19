# grade_runner

A Ruby client for [firstdraft Grades](https://grades.firstdraft.com)


## Installation

Add this line to your application's Gemfile:

```ruby
gem "grade_runner", github: "firstdraft/grade_runner"
```

And then execute:
```bash
$ bundle
```

## Usage

### Rails

After installed, run `rails grade` to run specs.

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
