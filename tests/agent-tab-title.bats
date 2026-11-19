#!/usr/bin/env bats
# Runs rex/.config/rex/agent-tab-title.sh with a fake rex command, so the test
# changes nothing in the running Rex server.

setup() {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  # The fake rex prints the title in $TITLE, gives the pane window w1 and
  # records each rename.
  cat > "$BATS_TEST_TMPDIR/bin/rex" <<EOF
#!/bin/sh
case "\$1 \$2" in
  "api call") printf '{"title":"%s"}\n' "\$TITLE" ;;
  "block inspect") printf '{"block":{"window_id":"w1"}}\n' ;;
  "window rename") echo "\$*" >> "$BATS_TEST_TMPDIR/rex.log" ;;
esac
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/rex"
}

run_hook() {
  PATH="$BATS_TEST_TMPDIR/bin:$PATH" REX_SESSION=s1 REX_BLOCK=b1 TITLE="$1" \
    run sh "$BATS_TEST_DIRNAME/../rex/.config/rex/agent-tab-title.sh"
}

@test "renames the pane's tab to the title without leading status characters" {
  run_hook '✳ Fix login redirect'

  [ "$status" -eq 0 ]
  [ "$(cat "$BATS_TEST_TMPDIR/rex.log")" = 'window rename -s s1 w1 Fix login redirect' ]
}

@test "removes omp's prefix and emoji" {
  run_hook 'π > 📦 PNPM: Summarise pnpm config'

  [ "$(cat "$BATS_TEST_TMPDIR/rex.log")" = 'window rename -s s1 w1 PNPM: Summarise pnpm config' ]
}

@test "leaves the tab alone when the pane has no title" {
  run_hook ''

  [ "$status" -eq 0 ]
  [ ! -e "$BATS_TEST_TMPDIR/rex.log" ]
}
