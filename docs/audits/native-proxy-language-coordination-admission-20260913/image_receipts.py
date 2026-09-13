"""Independently join recorded kernel executable paths to selected toolchain bytes."""

from pathlib import Path

from toolchain import native_candidate


def verify(rows, plan):
    starts = [row for row in rows if row['event'] == 'run_started']
    assert len(starts) == 1
    tools = starts[0]['toolchains']
    assert set(tools) == {'perl', 'python'}
    expected = {}
    for language, tool in tools.items():
        selected = plan['toolchains'][language]
        invocation = Path(tool['invocation'])
        assert invocation.is_absolute() and '..' not in invocation.parts
        assert invocation.name == selected['selected_sibling_basename']
        candidate = native_candidate(invocation, selected['native_image']['kind'])
        assert tool['native_image'] == str(candidate)
        assert tool['native_binary'] == selected['native_image']['binary']
        expected[language] = dict(path=str(candidate), **selected['native_image']['binary'])
    languages = {row['worker']: row['language'] for row in rows if row['event'] == 'launch_intent'}
    assert len(languages) == 20
    records = [row for row in rows if row['event'] in ('native_admitted', 'probe_native_admitted')]
    assert len(records) == 24
    assert len({(row['event'], row['worker']) for row in records}) == 24
    for row in records:
        assert row['native_image'] == expected[languages[row['worker']]]
    return dict(native_image_records=24, native_proxy_execution=False)
