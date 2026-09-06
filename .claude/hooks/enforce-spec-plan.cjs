#!/usr/bin/env node
/**
 * Enforce Spec + Plan — PreToolUse hook (blocking, OPT-IN, off by default).
 *
 * Blocks a source-code modification (Write/Edit/MultiEdit) unless the current
 * feature has BOTH an approved spec and an approved plan. Adopting this gate on
 * a repo is a governed, piloted decision — see ADR D-0011 (chrysa/shared-standards).
 *
 * ACTIVATION — the gate is a no-op unless `.claude/config/hooks-config.json` says:
 *   { "enforceSpecPlan": { "enabled": true, "gatedRoots": ["api/", ...] } }
 * With `enabled` absent/false, or `gatedRoots` empty, the hook exits 0 (allows
 * everything). Nothing is padam- or stack-specific — the gated roots and source
 * extensions come from config, so this file distributes to the fleet untouched.
 *
 * Workflow enforced (when enabled):
 *   1. /spec <feature>      -> reports/specs/<feature>.md   (status: draft)
 *   2. human review         -> set frontmatter status: approved
 *   3. /plan <feature>      -> reports/plans/<feature>.md   (status: draft)
 *   4. human review         -> set frontmatter status: approved
 *   5. /implement <feature> -> source edits now allowed
 *
 * Feature resolution (in priority order):
 *   1. .claude/.active-feature file (single line: the feature slug)
 *   2. git branch name feature|fix|chore|hotfix|release/<slug> -> <slug>
 *
 * Every decision (allow-through-gate / block) is appended to
 * reports/.spec-plan-gate.log as one JSON line, so the ADR kill-test
 * (`make spec-plan-gate-report`) can tally false blocks and time-to-first-edit.
 *
 * Exit codes: 0 = allow · 2 = block (stderr shown to Claude).
 *
 * @tag @[claude-opus-4-8]
 */

"use strict";

const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const DEFAULT_SOURCE_EXTS = [".py", ".pyi", ".ts", ".tsx", ".js", ".jsx", ".go", ".rs"];
// Paths that must never be blocked (needed to bootstrap the workflow).
const ALWAYS_ALLOWED_PREFIXES = ["reports/specs/", "reports/plans/", ".claude/"];

function loadConfig(cwd) {
	const p = path.join(cwd, ".claude", "config", "hooks-config.json");
	try {
		return JSON.parse(fs.readFileSync(p, "utf8")).enforceSpecPlan ?? {};
	} catch {
		return {};
	}
}

function readActiveFeature(cwd) {
	try {
		const slug = fs.readFileSync(path.join(cwd, ".claude", ".active-feature"), "utf8").trim();
		return slug || null;
	} catch {
		return null;
	}
}

function readBranchFeature(cwd) {
	try {
		const branch = execFileSync("git", ["rev-parse", "--abbrev-ref", "HEAD"], {
			cwd,
			encoding: "utf8",
			stdio: ["ignore", "pipe", "ignore"],
		}).trim();
		const m = branch.match(/^(?:feature|fix|chore|hotfix|release)\/(.+)$/);
		return m ? m[1].replace(/\//g, "-") : null;
	} catch {
		return null;
	}
}

/** Parse a leading YAML-ish frontmatter block and return its `status` value. */
function frontmatterStatus(filePath) {
	let content;
	try {
		content = fs.readFileSync(filePath, "utf8");
	} catch {
		return null; // missing file
	}
	const m = content.match(/^---\s*\n([\s\S]*?)\n---/);
	if (!m) return "no-frontmatter";
	const statusLine = m[1].split("\n").find((l) => /^status\s*:/.test(l.trim()));
	if (!statusLine) return "no-status";
	return statusLine.split(":")[1].trim().toLowerCase();
}

function toRelative(cwd, filePath) {
	const abs = path.isAbsolute(filePath) ? filePath : path.join(cwd, filePath);
	return path.relative(cwd, abs).split(path.sep).join("/");
}

function isGated(rel, gatedRoots, sourceExts) {
	if (ALWAYS_ALLOWED_PREFIXES.some((p) => rel.startsWith(p))) return false;
	if (gatedRoots.length === 0) return false; // nothing configured -> gate nothing
	const underGatedRoot = gatedRoots.some((r) => rel.startsWith(r));
	return underGatedRoot && sourceExts.includes(path.extname(rel));
}

function appendLog(cwd, entry) {
	try {
		const dir = path.join(cwd, "reports");
		fs.mkdirSync(dir, { recursive: true });
		fs.appendFileSync(path.join(dir, ".spec-plan-gate.log"), JSON.stringify({ ts: new Date().toISOString(), ...entry }) + "\n");
	} catch {
		/* logging is best-effort; never let it break the gate */
	}
}

function block(cwd, entry, message) {
	appendLog(cwd, { ...entry, decision: "block" });
	process.stderr.write(`[enforce-spec-plan] BLOCKED\n${message}\n`);
	process.exit(2);
}

let raw = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => (raw += chunk));
process.stdin.on("end", () => {
	let event = {};
	try {
		event = JSON.parse(raw);
	} catch {
		process.exit(0);
	}

	const toolName = event?.tool_name ?? "";
	if (!["Write", "Edit", "MultiEdit"].includes(toolName)) process.exit(0);

	const cwd = event?.cwd ?? process.cwd();
	const cfg = loadConfig(cwd);
	if (cfg.enabled !== true) process.exit(0); // opt-in: off by default

	const gatedRoots = Array.isArray(cfg.gatedRoots) ? cfg.gatedRoots : [];
	const sourceExts = Array.isArray(cfg.sourceExts) ? cfg.sourceExts : DEFAULT_SOURCE_EXTS;

	const filePath = event?.tool_input?.file_path ?? event?.tool_input?.path ?? "";
	if (!filePath) process.exit(0);

	const rel = toRelative(cwd, filePath);
	if (!isGated(rel, gatedRoots, sourceExts)) process.exit(0);

	const feature = readActiveFeature(cwd) ?? readBranchFeature(cwd);
	if (!feature) {
		block(
			cwd,
			{ feature: null, path: rel },
			`No active feature detected.\n` +
				`  Editing "${rel}" requires an approved spec + plan.\n` +
				`  -> Create a branch feature/<slug> (or write .claude/.active-feature),\n` +
				`     then run /spec <slug> and /plan <slug>.`,
		);
	}

	const specStatus = frontmatterStatus(path.join(cwd, "reports", "specs", `${feature}.md`));
	const planStatus = frontmatterStatus(path.join(cwd, "reports", "plans", `${feature}.md`));

	const problems = [];
	if (specStatus === null) problems.push(`spec missing: reports/specs/${feature}.md — run /spec ${feature}`);
	else if (specStatus !== "approved")
		problems.push(`spec not approved (status: ${specStatus}) — review reports/specs/${feature}.md then set 'status: approved'`);

	if (planStatus === null) problems.push(`plan missing: reports/plans/${feature}.md — run /plan ${feature}`);
	else if (planStatus !== "approved")
		problems.push(`plan not approved (status: ${planStatus}) — review reports/plans/${feature}.md then set 'status: approved'`);

	if (problems.length > 0) {
		block(
			cwd,
			{ feature, path: rel },
			`Feature "${feature}" is not ready for implementation.\n` +
				problems.map((p) => `  - ${p}`).join("\n") +
				`\n  Editing "${rel}" is blocked until spec AND plan are approved.`,
		);
	}

	appendLog(cwd, { feature, path: rel, decision: "allow" });
	process.exit(0);
});
