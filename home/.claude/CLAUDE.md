# Global rules

- Never run `git commit` in any form (including `git -C ... commit`, chained commands, or amend). Leave committing to me.
- Never stage changes (`git add`, `git stage`, `git commit -a`, `git add -p`, etc.). Leave the index to me.
- Before changing any file, show me the proposed change (diff or full new content) and wait for my approval. This applies equally to changes made through shell commands (`sed -i`, `echo >`, `tee`, etc.): show me what they will change before running them.
- These rules are about keeping me informed, not limiting what you can do. Use any tool or approach that fits the task; just get my approval first for file changes.
