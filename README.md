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

## Choosing an LLM provider (Phase 4)

Phase 4 ships three LLM adapters. `LLM::Client.auto_detect` picks one based on what's available, in this order:

1. **Claude**, if `ANTHROPIC_API_KEY` is set
2. **Ollama**, if `localhost:11434` accepts connections
3. **Null** otherwise (always works, no setup)

Any of the three will let you finish Phase 4. Don't have either of the first two? You're fine. Null is the default and every test passes against it.

### Null: zero setup

Uses word lists and a seeded `Random`. Deterministic, offline, no credentials.

```bash
bundle exec ruby -Ilib -r llm/null -r monster -e '
  puts LLM::Null.new.generate_identity(Monster.random).inspect
'
```

### Claude: needs an API key

Grab a key from https://console.anthropic.com (signup gives you free credit). Then:

```bash
export ANTHROPIC_API_KEY=sk-ant-...
bundle exec ruby -Ilib -r llm/claude -r monster -e '
  puts LLM::Claude.new.generate_identity(Monster.random).inspect
'
```

Each call costs a fraction of a cent on `claude-haiku-4-5`.

### Ollama: local, no API key

```bash
brew install ollama       # or download from ollama.com
ollama serve              # leave running in a separate terminal
ollama pull llama3.2      # ~2GB
```

Check it's listening:

```bash
curl http://localhost:11434
# => Ollama is running
```

Then try the adapter:

```bash
bundle exec ruby -Ilib -r llm/ollama -r monster -e '
  puts LLM::Ollama.new.generate_identity(Monster.random).inspect
'
```

First call takes 30–60s while the model loads into RAM. After that it's quick.
