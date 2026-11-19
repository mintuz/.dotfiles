// Connects omp to Rex.
// - Copies omp's terminal title, which holds the session name, to the Rex tab
//   that holds the pane. omp names the session a few seconds after the first
//   reply, so the script runs again 20 seconds after each run ends.
// - Records the session of the pane, so the Rex action Restore Agents… can
//   resume it after a Rex server restart.
import { execFile } from "node:child_process";

const rex = `${process.env.HOME}/.config/rex`;
const copyTitle = () => execFile(`${rex}/agent-tab-title.sh`, () => {});

type Context = { sessionManager: { getSessionId(): string; getCwd(): string } };

const recordSession = (_event: unknown, ctx: Context) => {
  const input = JSON.stringify({
    hook_event_name: "SessionStart",
    session_id: ctx.sessionManager.getSessionId(),
    cwd: ctx.sessionManager.getCwd(),
  });
  execFile(`${rex}/agent-session.sh`, ["omp"], () => {}).stdin?.end(input);
};

export default function (pi: { on(event: string, handler: (event: unknown, ctx: Context) => void): void }) {
  pi.on("agent_end", () => {
    copyTitle();
    setTimeout(copyTitle, 20_000).unref();
  });
  pi.on("session_start", recordSession);
  pi.on("session_switch", recordSession);
}
