# Disabled GitHub Actions Workflows

GitHub Actions is intentionally disabled for this repository for now to avoid
consuming account Actions minutes.

The regression workflow is parked here instead of under `.github/workflows/` so
GitHub will not discover or run it on pushes or pull requests.

To re-enable CI later, move the workflow back:

```sh
git mv .github/workflows-disabled/regression.yml .github/workflows/regression.yml
```

Then commit and push that change.
