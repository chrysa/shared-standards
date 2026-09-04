"use strict";
/**
 * Circuit Breaker — file-backed, usable from hooks and project scripts.
 *
 * States:
 *   CLOSED    — normal operation, requests pass through
 *   OPEN      — circuit tripped, requests fail immediately with fallback
 *   HALF_OPEN — testing recovery, one probe request allowed
 *
 * Usage:
 *   const { CircuitBreaker } = require('./.claude/hooks/lib/circuit-breaker.cjs');
 *   const cb = new CircuitBreaker('anthropic-api');
 *   const result = cb.call(async () => fetch(...), () => fallbackValue);
 */

const fs = require("fs");
const path = require("path");

const STATE_CLOSED = "CLOSED";
const STATE_OPEN = "OPEN";
const STATE_HALF_OPEN = "HALF_OPEN";

/**
 * Load the central hooks config, with safe defaults if missing.
 * @returns {object}
 */
function _loadConfig() {
	const configPath = path.resolve(process.cwd(), ".claude/config/hooks-config.json");
	try {
		return JSON.parse(fs.readFileSync(configPath, "utf8"));
	} catch {
		return {
			circuitBreaker: {
				failureThreshold: 3,
				resetTimeoutMs: 60000,
				halfOpenMaxAttempts: 1,
				stateFile: ".claude/state/circuit-breaker.json",
			},
		};
	}
}

/**
 * Load all circuit breaker states from the state file.
 * Returns an empty object if the file doesn't exist or is corrupt.
 * @param {string} stateFilePath
 * @returns {Record<string, object>}
 */
function _loadAllStates(stateFilePath) {
	try {
		const raw = fs.readFileSync(stateFilePath, "utf8");
		return JSON.parse(raw);
	} catch {
		return {};
	}
}

/**
 * Persist all circuit breaker states atomically via a temp file swap.
 * @param {string} stateFilePath
 * @param {Record<string, object>} allStates
 */
function _saveAllStates(stateFilePath, allStates) {
	const dir = path.dirname(stateFilePath);
	if (!fs.existsSync(dir)) {
		fs.mkdirSync(dir, { recursive: true });
	}
	const tmp = `${stateFilePath}.tmp.${process.pid}`;
	try {
		fs.writeFileSync(tmp, JSON.stringify(allStates, null, 2), "utf8");
		fs.renameSync(tmp, stateFilePath);
	} catch (err) {
		// Clean up tmp if rename failed
		try {
			fs.unlinkSync(tmp);
		} catch {
			/* ignore */
		}
		throw err;
	}
}

class CircuitBreaker {
	/**
	 * @param {string} name     Unique name for this breaker (e.g. 'anthropic-api')
	 * @param {object} [opts]   Optional overrides for thresholds and timeouts
	 * @param {number} [opts.failureThreshold]
	 * @param {number} [opts.resetTimeoutMs]
	 * @param {number} [opts.halfOpenMaxAttempts]
	 */
	constructor(name, opts = {}) {
		this._name = name;
		const cfg = _loadConfig().circuitBreaker || {};
		this._failureThreshold = opts.failureThreshold ?? cfg.failureThreshold ?? 3;
		this._resetTimeoutMs = opts.resetTimeoutMs ?? cfg.resetTimeoutMs ?? 60000;
		this._halfOpenMaxAttempts = opts.halfOpenMaxAttempts ?? cfg.halfOpenMaxAttempts ?? 1;
		this._stateFilePath = path.resolve(
			process.cwd(),
			opts.stateFile ?? cfg.stateFile ?? ".claude/state/circuit-breaker.json",
		);
	}

	/** @returns {object} Current state record for this breaker's name */
	_getState() {
		const all = _loadAllStates(this._stateFilePath);
		return (
			all[this._name] || {
				state: STATE_CLOSED,
				failures: 0,
				lastFailureTime: null,
				halfOpenAttempts: 0,
			}
		);
	}

	/** @param {object} record */
	_setState(record) {
		const all = _loadAllStates(this._stateFilePath);
		all[this._name] = record;
		_saveAllStates(this._stateFilePath, all);
	}

	_log(msg) {
		process.stderr.write(`[CircuitBreaker:${this._name}] ${msg}\n`);
	}

	/**
	 * Returns effective state, auto-transitioning OPEN→HALF_OPEN after timeout.
	 * @returns {{ state: string, failures: number, lastFailureTime: number|null, halfOpenAttempts: number }}
	 */
	_resolveState() {
		const record = this._getState();
		if (record.state === STATE_OPEN && record.lastFailureTime != null) {
			const elapsed = Date.now() - record.lastFailureTime;
			if (elapsed >= this._resetTimeoutMs) {
				const updated = { ...record, state: STATE_HALF_OPEN, halfOpenAttempts: 0 };
				this._setState(updated);
				this._log(`state → HALF_OPEN (reset timeout elapsed: ${elapsed}ms)`);
				return updated;
			}
		}
		return record;
	}

	/**
	 * Execute fn with circuit breaker protection.
	 * If the circuit is OPEN, fallbackFn is called immediately.
	 *
	 * @template T
	 * @param {() => Promise<T>} fn          The protected async call
	 * @param {() => T}          fallbackFn  Called when circuit is open
	 * @returns {Promise<T>}
	 */
	async call(fn, fallbackFn) {
		const record = this._resolveState();

		if (record.state === STATE_OPEN) {
			const remaining = this._resetTimeoutMs - (Date.now() - (record.lastFailureTime || 0));
			this._log(`OPEN — using fallback (reset in ~${Math.ceil(remaining / 1000)}s)`);
			return fallbackFn();
		}

		if (record.state === STATE_HALF_OPEN) {
			if (record.halfOpenAttempts >= this._halfOpenMaxAttempts) {
				this._log(`HALF_OPEN — probe limit reached, using fallback`);
				return fallbackFn();
			}
			// Increment probe counter before the call
			this._setState({ ...record, halfOpenAttempts: record.halfOpenAttempts + 1 });
		}

		try {
			const result = await fn();
			this._onSuccess(record);
			return result;
		} catch (err) {
			this._onFailure(record, err);
			throw err;
		}
	}

	/** @param {object} record */
	_onSuccess(record) {
		if (record.state !== STATE_CLOSED) {
			this._log(`state → CLOSED (recovered)`);
		}
		this._setState({
			state: STATE_CLOSED,
			failures: 0,
			lastFailureTime: null,
			halfOpenAttempts: 0,
		});
	}

	/** @param {object} record @param {Error} err */
	_onFailure(record, err) {
		const newFailures = (record.failures || 0) + 1;
		const willOpen = newFailures >= this._failureThreshold;
		const newState = willOpen ? STATE_OPEN : record.state;

		this._log(`failure #${newFailures}${willOpen ? ` — threshold reached, state → OPEN` : ""}: ${err.message}`);

		this._setState({
			state: newState,
			failures: newFailures,
			lastFailureTime: Date.now(),
			halfOpenAttempts: record.halfOpenAttempts || 0,
		});
	}

	/**
	 * Force-reset this breaker to CLOSED state.
	 * Useful for manual recovery after an incident.
	 */
	reset() {
		this._setState({
			state: STATE_CLOSED,
			failures: 0,
			lastFailureTime: null,
			halfOpenAttempts: 0,
		});
		this._log(`manually reset to CLOSED`);
	}

	/**
	 * Returns a snapshot of the current state for logging/debugging.
	 * @returns {{ name: string, state: string, failures: number, lastFailureTime: number|null }}
	 */
	status() {
		const record = this._resolveState();
		return { name: this._name, ...record };
	}
}

module.exports = { CircuitBreaker, STATE_CLOSED, STATE_OPEN, STATE_HALF_OPEN };
