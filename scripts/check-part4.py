#!/usr/bin/env python3
"""Audit the frozen Part 4 intent experiment; no API calls or wording pins.
Run: python3 scripts/check-part4.py
Recomputes decisions/quality and cache-aware costs from raw recorded responses.
"""
from collections import Counter
import csv
import hashlib
import json
import math
from pathlib import Path
import statistics

root = Path(__file__).resolve().parent.parent
evidence_root = root / 'artifacts/article-series/part-4-coding'
primary = evidence_root / 'account-closure-comparison-2026-10-04'
boundary = evidence_root / 'account-closure-boundaries-2026-10-04'
source_directory = evidence_root / 'routing-comparison-2026-10-04'


def load(path):
    return json.loads(path.read_text())


def cost(model, usage, rates, scenario):
    rate = rates[model]
    if model == 'jev-1.13.0':
        return usage['input_tokens'] * rate['input'] / 1e6
    inputs, output = usage['inputTokens'], usage['outputTokens']
    cached, writes = usage['cachedInputTokens'], usage.get('cacheWriteInputTokens', 0)
    assert inputs >= cached + writes >= 0, 'Impossible cached/write accounting'
    if scenario == 'cold':
        cached, writes = 0, 0
    elif scenario == 'fully_cached':
        cached, writes = inputs, 0
    return ((inputs - cached - writes) * rate['input'] + cached * rate['cached']
            + writes * rate['write'] + output * rate['output']) / 1e6


def audit(directory, threshold):
    data, protocol = load(directory / 'dataset.json'), load(directory / 'protocol.json')
    rows, reported = load(directory / 'results.json'), load(directory / 'summary.json')
    assert hashlib.sha256((directory / 'dataset.json').read_bytes()).hexdigest() == protocol['dataset_sha256']
    cases = {case['id']: case for cohort in data['cases'].values() for case in cohort}
    evaluation_counts = Counter()
    for row in rows:
        cohort = [cases[case_id] for case_id in row['case_ids']]
        state = {'queries': {f'q{index}': case['text'] for index, case in enumerate(cohort)}}
        if row['model'] == 'jev-1.13.0':
            response = row['raw_response']
            assert row['request']['state'] == state and response['model'] == row['model']
            assert row['usage'] == response['usage']
            raw = {query: answer['choice'] for query, answer in response['answers'].items()}
            automatic = {query: answer['confidence'] >= threshold for query, answer in response['answers'].items()}
            for query, question in row['request']['questions'].items():
                assert question['criteria'] == data['criteria']
                assert question['instructions'] == data['instructions'] + f' Evaluate only `queries.{query}` in state.'
        else:
            prompt = row['request']['prompt']
            assert prompt['state'] == state and prompt['criteria'] == data['criteria']
            assert prompt['instructions'] == data['instructions']
            final_messages = [event['params']['item']['text'] for event in row['raw_events']
                              if event.get('method') == 'item/completed'
                              and event['params']['item']['type'] == 'agentMessage']
            raw = json.loads(final_messages[-1])
            usage = [event['params']['tokenUsage']['last'] for event in row['raw_events']
                     if event.get('method') == 'thread/tokenUsage/updated'][-1]
            assert row['usage'] == usage
            automatic = {query: True for query in raw}
        assert set(raw) == set(state['queries'])
        assert len(row['decisions']) == len(cohort), 'Missing or duplicated scored decisions'
        for index, (case, decision) in enumerate(zip(cohort, row['decisions'])):
            query = f'q{index}'
            choice = raw[query] if automatic[query] else 'unclear'
            assert decision == {'case_id': case['id'], 'expected': case['expected_route'],
                                'raw_choice': raw[query], 'choice': choice,
                                'correct': choice == case['expected_route'], 'automatic': automatic[query]}
            if row['phase'] == 'evaluation':
                evaluation_counts[row['model'], case['id']] += 1
        for scenario, key in [('observed', 'estimated_usd'), ('cold', 'cold_equivalent_usd'),
                              ('fully_cached', 'fully_cached_equivalent_usd')]:
            assert math.isclose(row[key], cost(row['model'], row['usage'], protocol['pricing'], scenario), rel_tol=1e-12)
    for model, arm in reported['arms'].items():
        selected = [row for row in rows if row['model'] == model and row['phase'] == 'evaluation']
        decisions = [decision for row in selected for decision in row['decisions']]
        automatic = [decision for decision in decisions if decision['automatic']]
        assert all(evaluation_counts[model, case['id']] == protocol['evaluation_repeats'] for case in data['cases']['evaluation'])
        assert arm['correct'] == sum(decision['correct'] for decision in decisions)
        assert arm['scored_decisions'] == len(decisions)
        assert math.isclose(arm['accuracy'], arm['correct'] / len(decisions))
        assert math.isclose(arm['coverage'], len(automatic) / len(decisions))
        assert math.isclose(arm['automatic_precision'], sum(d['correct'] for d in automatic) / len(automatic))
        assert math.isclose(arm['median_batch_s'], statistics.median(row['elapsed_s'] for row in selected))
        for scenario, key in [('observed', 'estimated_usd_per_100_queries'), ('cold', 'cold_equivalent_usd_per_100_queries'),
                              ('fully_cached', 'fully_cached_equivalent_usd_per_100_queries')]:
            total = sum(cost(model, row['usage'], protocol['pricing'], scenario) for row in selected)
            assert math.isclose(arm[key], total / len(decisions) * 100, rel_tol=1e-12)
    jev = reported['arms']['jev-1.13.0']
    for model, comparison in reported['comparisons'].items():
        baseline = reported['arms'][model]
        quality = jev['accuracy'] >= baseline['accuracy'] and jev['coverage'] >= baseline['coverage']
        win = (quality and jev['automatic_precision'] >= .95
               and jev['median_batch_s'] <= .8 * baseline['median_batch_s']
               and jev['estimated_usd_per_100_queries'] <= .8 * baseline['estimated_usd_per_100_queries']
               and jev['cold_equivalent_usd_per_100_queries'] <= .8 * baseline['cold_equivalent_usd_per_100_queries'])
        assert comparison['quality_not_worse_observed'] == quality
        assert comparison['publishable_for_tested_integration'] == win
    print(f'PASS: {directory.name}: {len(rows)} real calls; raw labels, quality, parity, repetitions, cache prices and gates verified')
    return data


policy = load(primary / 'calibration.json')['chosen']
primary_data = audit(primary, policy['threshold'])
for split, source in primary_data['source'].items():
    csv_path = source_directory / f'{split}.csv'
    assert hashlib.sha256(csv_path.read_bytes()).hexdigest() == source['sha256']
    with csv_path.open() as stream:
        original = list(csv.DictReader(stream))
    assert len(original) == source['rows']
    phase = 'calibration' if split == 'train' else 'evaluation'
    for case in primary_data['cases'][phase]:
        assert original[case['source_row']] == {'text': case['text'], 'category': case['original_intent']}
        assert case['expected_route'] == ('closure_request' if case['original_intent'] == 'terminate_account' else 'not_closure')
cohorts = [{case['text'] for case in cohort} for cohort in primary_data['cases'].values()]
assert not cohorts[0] & cohorts[1]
previous = {case['text'] for cohort in load(source_directory / 'dataset.json')['cases'].values() for case in cohort}
assert not set.union(*cohorts) & previous
boundary_data = audit(boundary, policy['threshold'])
assert boundary_data['inherited_calibration']['threshold'] == policy['threshold']
assert boundary_data['criteria'] == primary_data['criteria'] and boundary_data['instructions'] == primary_data['instructions']
print('PASS: original public texts/labels and hashes; isolated cohorts; boundary rubric and cutoff inherited without tuning')
