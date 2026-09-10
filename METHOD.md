# METHOD.md — the method, without the tool

`attest` is a kit for one AI coding agent. **This file is the idea underneath it**, written so
it does not depend on that agent — or on any agent at all. Read it if you want the method and
intend to implement it yourself, in another tool, in your CI, or as a rule your team follows by
hand. Nothing here is code, and nothing here requires ours.

The kit that implements this method is described in [`README.md`](README.md); the method is
older and smaller than the kit, and it will outlive it.

## The problem

An AI agent can change a repository faster than the people who own it can re-derive **why the
repository is the way it is**. The code says *what*. It does not say which boundary was
deliberate, which choice was made against a real alternative, which line exists because a
regulator requires it. A human contributor picks that up from context over weeks. An agent
starts from nothing every session, and writes anyway.

So the repository has to carry its own declaration, and every change has to be checked against
it **before it lands** — not reconstructed afterwards from a diff.

## The spine

    intent  →  boundaries  →  decisions  →  compliance  →  clean history

Five questions a repository must be able to answer about itself, each with exactly one home:

| The question | What lives there |
|---|---|
| **Why does this exist?** | purpose, and — the load-bearing half — the **non-goals**: what it deliberately does not do |
| **Where are we?** | current state, carried across context resets |
| **What rules do we work under?** | conventions: language, tests, formatting, commit style |
| **Why X over Y?** | decisions, append-only, with the options that were rejected |
| **Under what external rules?** | regulatory posture — only where there is one |

Prose, in version control, next to the code. Not a database, not a dashboard, not a YAML
manifest: the consumer is a language model and a human reviewer, and both read prose better
than schema. Keep the first one — the rules file — small, because it is the one thing the agent
reads on every single turn; the rest are read on demand.

The non-goals section is the one that earns its keep. It is the only place a repository states
what a change is allowed to be measured against.

## Two gates, two cadences

**At commit time** — before the change is recorded: does it violate a declared boundary, does
it contain a decision nobody wrote down, does it touch regulated ground the declared posture
does not cover, and does it hold up as code.

**At ship time** — before anything leaves the machine: does the history carry a secret,
personal data, a client's name, an internal hostname. This is a different question on a
different clock, and merging the two is how one of them gets skipped.

## What makes it work

The list below is the transferable part. Skip these and you have a folder of documents nobody
consults.

1. **The declaration reaches the agent before the first edit.** A boundary in a file the agent
   *may* open is not a boundary. Inject the non-goals and the current state into its context at
   the start of the session, capped in size, whether or not it asks.

2. **Audit reality against the document — not the document against itself.** The check is
   *"does the repo still match what you declared"*, not *"is this file well-formed"*. A
   linter for prose proves nothing.

3. **Restrain by capability, not by instruction.** The thing that reviews a change should be
   *unable* to modify the repo — no write, no shell — rather than asked not to. Where a host
   cannot enforce that, the guarantee is weaker, and saying so is part of the method.

4. **One finding, one owner.** When several checks look at one change, each reports only its
   own aspect and names the others' ground instead of repeating it. Triple-reported findings
   train people to skim.

5. **A gate leaves evidence.** Every run appends a dated record naming the exact commit, what
   ran, and the verdict — so *"this state was audited"* is a fact in the repository rather than
   somebody's memory. Evidence tied to a commit, not to a date, and not to a file merely
   existing.

6. **Refuse to fabricate.** An agent that invents the rationale for a decision nobody explained
   produces a record that is worse than no record — it is confidently wrong, append-only, and
   will be cited. Escalate to a human instead.

7. **One fact, one home.** Duplicated facts drift apart, and then the agent obeys whichever
   copy it read last. Route every fact to exactly one file, and make the routing table part of
   the documents.

8. **Adopt on a gradient.** Three documents is a working minimum; the rest cost nothing while
   absent, and every check degrades to a note rather than a failure when a document it wanted
   is not there. A method with an all-or-nothing entry price does not get adopted.

9. **A guard that cannot be overridden gets deleted.** Make it ask, state precisely what is
   missing, and let a human approve. Guards survive by being useful, not by being absolute.

10. **What blocks must be deterministic.** A judgment-based verdict — one produced by a model
    reading a diff — is stable on its primary finding and varies on the margins. That is
    perfectly good *advice*, and a bad basis for refusing a merge. Let judgment comment; let
    only reproducible checks block.

## What an implementation needs from its host

Four primitives. A host that has all four can enforce the method; one that has fewer can still
follow it, with a weaker guarantee that should be named rather than glossed over.

| Primitive | Used for |
|---|---|
| Inject context at session start | property 1 — boundaries known before the first edit |
| Intercept an action before it runs | the ship gate — catch the publish, not regret it |
| A reviewer with reduced capability | property 3 — read-only by construction |
| Read a document on demand | keeping the always-loaded surface small |

Missing the first, the declaration becomes a file the agent might read. Missing the second, the
ship gate becomes a thing you remember on a good day. Missing the third, the reviewer is
trusted rather than constrained. None of that makes the method worthless — a team can run all
of it by hand — but the difference between *enforced* and *encouraged* is exactly the
difference an auditor will ask about, so state which one you have.

## What it costs, and where it is thin

The documents have to be maintained; a stale declaration audits worse than none, because it
launders drift as approval. The commit-time gate costs a model run per commit. The judgment
passes vary on secondary findings across runs — treat a blocker as reliable and a minor as
advisory.

The method also has a seam that property 3 does not close. Evidence (property 5) is a file, and a
file is written by something — so a host that cannot restrain *writing* leaves the attestation
resting on trust even where the review itself is properly constrained. The honest mitigations are
to make writing the evidence a decision a human sees, and to say plainly that what you have
defends against forgetting rather than against forgery. Claiming otherwise would fail the method
at its own first property: declare what is true, then check reality against the declaration.

And the evidence base is small: the reference implementation was dogfooded on **two sandboxes
seeded with six known planted faults — 6/6 caught at the right severity, 0 false positives**
([the record](docs/attest-devlog.md)). Six faults, two sandboxes. That is a clean sweep, not a
benchmark, and it is quoted here with the sample size attached for the same reason the method
exists at all.

## The reference implementation

[`attest`](README.md) implements every property above for Claude Code, which has all four
primitives. It is one implementation, not the method. If you build another, the method asks
only this of you: say which of the four primitives your host actually gives you, and do not
sell *encouraged* as *enforced*.

MIT. Take the idea.
