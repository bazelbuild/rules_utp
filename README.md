# UTP bazel rules

This github repository provides the support to run tests on UTP with bazel.

### Relevant Links

Sources:

- [Google source](https://utp.googlesource.com/rules_utp)
- [GoB](https://utp.git.corp.google.com/rules_utp)
- [Gerrit site](https://utp-review.git.corp.google.com/)
- [Github site](https://github.com/bazelbuild/rules_utp)


Copybara job list:

- [presubmit_piper_to_gerrit](https://copybara.corp.google.com/list-jobs?piperConfigPath=%2F%2Fdepot%2Fgoogle3%2Fthird_party%2Fbazel_rules%2Frules_utp%2Fcopybara%2Fcopy.bara.sky&workflowName=presubmit_piper_to_gerrit)
- [postsubmit_piper_to_gob](https://copybara.corp.google.com/list-jobs?piperConfigPath=%2F%2Fdepot%2Fgoogle3%2Fthird_party%2Fbazel_rules%2Frules_utp%2Fcopybara%2Fcopy.bara.sky&workflowName=postsubmit_piper_to_gob)
- [mirror_gob_to_github](https://copybara.corp.google.com/list-jobs?piperConfigPath=%2F%2Fdepot%2Fgoogle3%2Fthird_party%2Fbazel_rules%2Frules_utp%2Fcopybara%2Fcopy.bara.sky&workflowName=mirror_gob_to_github&refs=)
- [feedback_gerrit_to_critique](https://copybara.corp.google.com/list-jobs?piperConfigPath=%2F%2Fdepot%2Fgoogle3%2Fthird_party%2Fbazel_rules%2Frules_utp%2Fcopybara%2Fcopy.bara.sky&workflowName=feedback_gerrit_to_critique&refs=)


### Troubleshooting

#### Copybara failed to push to rpc://utp/rules_utp
If you see
`REJECTED_OTHER_REASON: Pushing to the ref 'refs/heads/main' requires a justification: git push -o push-justification='b/bug_id'` in the log.

Open the postsubmit_piper_to_gob job list. Find the reference of the job before the one with the failure to push. (`LAST_REVISION=<references of last commit>`) 

Another way to double check you've picked up the right revision: go to GoB and open the latest commit in main branch and find the tag in commit message `PiperOrigin-RevId: <references>`.

FYI: If jobs following the job with references you picked are `NO_OP`, you can skip ahead to use the references of the last consecutive `NO_OP` job.

Run this command from piper head:
```
copybara  third_party/bazel_rules/rules_utp/copybara/copy.bara.sky postsubmit_piper_to_gob --git-push-option=push-justification="b/316992393"  --ignore-noop --last-rev=$LAST_REVISION --dry-run
```

Ideally you will only see one new commit in local git directory, comparing to GoB's main branch, if you run this command right after a failed postsubmit. If you wait for several failed postsubmits before manually running this command, you could see multiple git commits.

If the local git history looks good, run the command again without `--dry-run` flag.

Cause of the issue: copybara-worker doesn't have permission to push to GoB's main branch. We have an pending request to GoB team for it: b/318574244.

#### Copybara services are out of date

If the Copybara:ServiceAutoUpdate chip shows up on a CL with a message like "Failed to apply diffs":

You can run following command from piper HEAD to see if copybara-as-service doesn't pick up updated configuration:

`copybara service diffall third_party/bazel_rules/rules_utp/copybara/copy.bara.sky`

Run `copybara service updateall third_party/bazel_rules/rules_utp/copybara/copy.bara.sky` to update all outdated services at once.
