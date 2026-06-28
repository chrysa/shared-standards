"""Presidio-backed PII scanner: build the engine and scan text into Findings."""

import hashlib
from dataclasses import dataclass

from presidio_analyzer import AnalyzerEngine  # type: ignore[import-not-found]
from presidio_analyzer.nlp_engine import NlpEngineProvider  # type: ignore[import-not-found]

from scripts.pii.config import ScanConfig
from scripts.pii.recognizers import build_custom_recognizers

SELFTEST_SAMPLE = "Email test.user@example.com"
_MODELS = {"fr": "fr_core_news_sm", "en": "en_core_web_sm"}


def build_analyzer(cfg: ScanConfig) -> AnalyzerEngine:
    """Assemble an AnalyzerEngine for the configured languages + custom recognizers."""
    models = [{"lang_code": lang, "model_name": _MODELS[lang]} for lang in cfg.languages]
    provider = NlpEngineProvider(
        nlp_configuration={"nlp_engine_name": "spacy", "models": models}
    )
    analyzer = AnalyzerEngine(
        nlp_engine=provider.create_engine(),
        supported_languages=cfg.languages,
    )
    for recognizer in build_custom_recognizers():
        analyzer.registry.add_recognizer(recognizer)
    return analyzer


@dataclass(frozen=True)
class Finding:
    path: str
    line: int
    entity: str
    score: float
    fingerprint: str


def scan_text(analyzer: AnalyzerEngine, cfg: ScanConfig, path: str, text: str) -> list[Finding]:
    """Return findings above the score threshold for one file's text."""
    lang = cfg.languages[0]
    results = analyzer.analyze(text=text, language=lang, entities=cfg.entities)
    findings: list[Finding] = []
    for res in results:
        if res.score < cfg.score_threshold:
            continue
        line = text.count("\n", 0, res.start) + 1
        matched = text[res.start:res.end]
        findings.append(_to_finding(path, line, res.entity_type, res.score, matched))
    return findings


def _to_finding(path: str, line: int, entity: str, score: float, matched: str) -> Finding:
    digest = hashlib.sha256(f"{entity}|{path}|{line}|{matched}".encode()).hexdigest()
    return Finding(path=path, line=line, entity=entity, score=round(score, 3), fingerprint=digest)


def selftest(cfg: ScanConfig) -> bool:
    """Return True if recognizers load and flag a known dirty sample."""
    analyzer = build_analyzer(cfg)
    return len(scan_text(analyzer, cfg, "<selftest>", SELFTEST_SAMPLE)) >= 1
