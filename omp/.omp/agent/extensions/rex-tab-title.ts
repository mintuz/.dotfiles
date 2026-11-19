// Copies omp's terminal title, which holds the session name, to the Rex tab
// that holds the pane. omp names the session a few seconds after the first
// reply, so the script runs again 20 seconds after each run ends.
import { execFile } from "node:child_process";

const script = `${process.env.HOME}/.config/rex/agent-tab-title.sh`;
const copyTitle = () => execFile(script, () => {});

export default function (pi: { on(event: string, handler: () => void): void }) {
  pi.on("agent_end", () => {
    copyTitle();
    setTimeout(copyTitle, 20_000).unref();
  });
}
