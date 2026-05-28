# evolving-monsters-workshop

A hands-on workshop for learning Ruby and genetic algorithms from the ground up. Each phase is implemented from scratch on its own branch, with tests as the spec.

## Prerequisites

- Ruby `>= 3.4` (see `.ruby-version` — currently `3.4.2`)
- Bundler

## Setup

```bash
bundle install
```

## Running the tests

```bash
bundle exec rake test
```

You can also run a single file or a single test:

```bash
# one file
ruby -Ilib -Itest test/monster_test.rb

# one test method
ruby -Ilib -Itest test/monster_test.rb -n test_normalize_genome_largest_remainder
```
