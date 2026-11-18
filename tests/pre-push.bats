#!/usr/bin/env bats
# Runs .githooks/pre-push in a temporary repo that pushes to a temporary bare remote.

setup() {
  command -v gitleaks >/dev/null || skip "gitleaks is not installed"
  remote="$BATS_TEST_TMPDIR/remote.git"
  repo="$BATS_TEST_TMPDIR/repo"
  git init -q --bare "$remote"
  git init -q -b main "$repo"
  cd "$repo"
  git config user.email test@example.com
  git config user.name test
  git config core.hooksPath "$BATS_TEST_DIRNAME/../.githooks"
  git remote add origin "$remote"
  commit clean.txt 'hello'
  git push -q --no-verify origin main
}

commit() {
  printf '%s\n' "$2" > "$1"
  git add "$1"
  git commit -q -m "add $1"
}

# Built at run time so this file holds no token for gitleaks to find.
token() {
  printf 'ghp_%s' 'Zq8Lm2Xv7Rt4Nw9Kp3Hb6Jd1Fs5Gc0Ya8Ue2W'
}

@test "lets a push with no secrets through" {
  commit notes.txt 'nothing secret'

  run git push origin main

  [ "$status" -eq 0 ]
}

@test "stops a push that adds a secret" {
  commit config.txt "GITHUB_TOKEN=$(token)"

  run git push origin main

  [ "$status" -ne 0 ]
  [[ "$output" == *"gitleaks found possible secrets in refs/heads/main"* ]]
  [ "$(git rev-parse main)" != "$(git --git-dir="$remote" rev-parse main)" ]
}

@test "stops a new branch that adds a secret" {
  git switch -q -c feature
  commit config.txt "GITHUB_TOKEN=$(token)"

  run git push origin feature

  [ "$status" -ne 0 ]
}

@test "does not scan commits the remote already has" {
  commit config.txt "GITHUB_TOKEN=$(token)"
  git push -q --no-verify origin main
  git switch -q -c feature
  commit notes.txt 'nothing secret'

  run git push origin feature

  [ "$status" -eq 0 ]
}
