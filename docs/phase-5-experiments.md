# Phase 5 experiments

Phase 5's name is "Emergence & Experimentation." This is the experimentation half.

The GA system you built in Phases 1-4, plus the visualization and analytics from Phase 5, behaves very differently depending on how you set the parameters. Each experiment below is a 3-5 minute "try this, observe that" loop. Pick whichever ones catch your interest.

All commands assume you're at the workshop root with `bundle install` done. Default `--llm null` keeps runs offline and reproducible. Swap to `--llm auto` (with `ANTHROPIC_API_KEY` set) if you want Claude's narration too.

## 1. Diversity collapse vs survival

**Hypothesis:** low mutation collapses fast; high mutation sustains diversity.

```bash
./bin/evolve --llm null --population 8 --generations 15 --mutation-rate 0.02 --seed 1
./bin/evolve --llm null --population 8 --generations 15 --mutation-rate 0.20 --seed 1
```

**Watch:** the diversity sparkline at the bottom of the Emergence section, and whether "(converged tightly)" appears next to the archetype.

**Why it matters:** mutation is the GA's only mechanism for re-introducing variance once selection has homogenized the population. Too low and you collapse early; too high and selection can't make progress. The right rate depends on the fitness landscape.

## 2. Crossover strategy comparison

**Hypothesis:** single-point keeps attribute groups together; uniform mixes more.

```bash
./bin/evolve --llm null --population 12 --generations 10 --crossover single_point --seed 42
./bin/evolve --llm null --population 12 --generations 10 --crossover uniform --seed 42
```

**Watch:** the drift table. Do attributes drift together (linked, single_point) or independently (uniform)?

**Why it matters:** Crossover strategies make different assumptions about which genes are "linked." Single-point preserves contiguous blocks. Uniform doesn't. If your problem has natural linkage between adjacent genes, single-point respects it; if genes are independent, uniform mixes faster.

## 3. Reproducibility check

**Hypothesis:** same seed produces byte-identical output.

```bash
./bin/evolve --llm null --seed 42 > /tmp/run1.txt
./bin/evolve --llm null --seed 42 > /tmp/run2.txt
diff /tmp/run1.txt /tmp/run2.txt
```

**Watch:** `diff` should produce zero output.

**Why it matters:** reproducibility is what makes GA experiments scientifically credible. If you can't reproduce a run, your result is anecdote. The seeded `Random.new(seed)` threaded through every random call in Phase 5 is what makes this work.

## 4. Selection pressure

**Hypothesis:** bigger tournaments select harder for the fittest and collapse faster.

```bash
./bin/evolve --llm null --population 20 --tournament-size 2 --seed 7
./bin/evolve --llm null --population 20 --tournament-size 8 --seed 7
```

**Watch:** how quickly the archetype emerges and whether collapse fires.

**Why it matters:** tournament size is the selection-pressure dial. Size 2 is nearly random; size = population means "always pick the best." Multimodal landscapes (lots of local optima) prefer lower pressure so the GA keeps exploring. Unimodal landscapes (one clear peak) prefer higher pressure for faster convergence.

## 5. Elitism extremes

**Hypothesis:** zero elitism allows the best to disappear; high elitism causes stagnation.

```bash
./bin/evolve --llm null --population 10 --elitism 0 --seed 11
./bin/evolve --llm null --population 10 --elitism 5 --seed 11
```

**Watch:** the `best=` value as generations progress. Does it climb monotonically (elitism preserves) or dip (without elitism, good monsters can be replaced by worse children)?

**Why it matters:** elitism is the GA's memory mechanism. Without it, crossover and mutation noise can destroy good solutions. With too much, the population can't escape local optima.

## 6. Population vs generations

**Hypothesis:** with the same total search budget, a wide-but-shallow run finds different solutions than a deep-but-narrow one.

```bash
./bin/evolve --llm null --population 50 --generations 5 --seed 17
./bin/evolve --llm null --population 10 --generations 25 --seed 17
```

Both do 250 monster-generations of work total. The first looks around a lot but barely evolves. The second evolves a tiny pool through many rounds.

**Watch:** compare the final archetype, the best fitness, and the diversity sparkline. The wide run usually keeps more diversity but doesn't move much. The deep run collapses faster but ends up with monsters that are noticeably more specialized.

**Why it matters:** the same compute splits very differently between exploration (population size) and exploitation (generations). If you've got a fixed budget, you have to pick. Wide bets are good when you don't trust your fitness landscape yet; deep bets are good once you do.

## 7. Bring Claude into the loop

**Hypothesis:** with diversity-aware prompts, Claude's narration explicitly references the dynamics.

```bash
export ANTHROPIC_API_KEY=sk-ant-...
./bin/evolve --llm auto --population 8 --generations 8 --narrate-every 3
```

**Watch:** does Claude's final narration mention collapse, drift, or archetype formation? Compare against the Null adapter's mechanical sentence (same command but `--llm null`).

**Why it matters:** Phase 4 added the diversity drift line to the evolution prompt. Phase 5's diversity computation feeds it real data. The narration is the cross-phase payoff.

## Going further

Try to break the system:

```bash
./bin/evolve --llm null --population 2                                        # minimum viable
./bin/evolve --llm null --mutation-rate 1.0                                   # almost random search
./bin/evolve --llm null --crossover-rate 0.0                                  # cloning + mutation only
./bin/evolve --llm null --generations 100 --seed 42                           # long-run dynamics
./bin/evolve --llm null --elitism 0 --mutation-rate 0.5 --tournament-size 2   # chaos config
```

Or modify the code:

- Change `Monster::BUDGET` from 100 to 200. Bigger search space.
- Add a sixth attribute to `Monster::ATTRIBUTES`. What happens to diversity numbers?
- Tweak `Race::STAGES` weights. What fitness landscape does that produce?
- Replace tournament selection with roulette-wheel selection in `GeneticAlgorithm#select`. How does drift change?

There's no wrong experiment. You're building intuition for how the dials interact.
