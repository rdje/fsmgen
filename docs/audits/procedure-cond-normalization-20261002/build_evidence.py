from pathlib import Path

out=Path('docs/audits/procedure-cond-normalization-20261002')
prior=Path('docs/audits/conditional-macro-intent-20261002')
helper=(prior/'verify.py').read_text().split('def verify():')[0]
helper=helper.replace('9bf0bd4c8af8c8aab5ab6865e66f6729d9583b3c','518d99d288b6b1cf4fd2f8f38518d684d37740a6')
helper=helper.replace("'first_proc_select', 'first_proc_when_bit', 'first_select_zero',","'first_proc_select', 'first_proc_when_bit', 'first_proc_cond', 'first_select_zero',")
helper=helper.replace("PROC_REFUSED = {'first_proc_cond', 'later_proc_cond'}","PROC_REFUSED = set()")
helper=helper.replace("BASE / 'sources' / (name + '.isf')", "BASE / 'macro-sources' / (name + '.isf')")
(out/'macro_validate.py').write_text(helper)
prefix=(prior/'seal.py').read_text().split('def collect():')[0]
prefix=prefix.replace("Path('.artifacts/conditional-macro-intent')","Path('.artifacts/procedure-cond-normalization')")
prefix=prefix.replace('9bf0bd4c8af8c8aab5ab6865e66f6729d9583b3c','518d99d288b6b1cf4fd2f8f38518d684d37740a6')
suffix='''def collect():
    assert not (BASE / 'manifest.json').exists(), 'sealed archive is immutable'
    assert (SCRATCH / 'boundary-test-final.t').read_bytes() == Path('t/2042-isf-procedure-cond-normalization.t').read_bytes()
    assert Path('t/2041-isf-conditional-macro-intent-qualification.t').read_bytes() == subprocess.check_output(['git','show',BASELINE+':t/2041-isf-conditional-macro-intent-qualification.t'])
    hashes = {}
    for source in sorted(p for p in SCRATCH.rglob('*') if p.is_file()):
        assert not source.is_symlink()
        relative = source.relative_to(SCRATCH)
        target = BASE / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        original = source.read_bytes()
        retained = original.replace(ROOT.encode(), b'')
        target.write_bytes(retained)
        hashes[str(relative)] = dict(original_sha256=sha(original), retained_sha256=sha(retained), normalization='exact runtime repository prefix only')
    write_json(BASE / 'normalization.json', hashes)
    raw, entries = tree(BASELINE, ['bin', 'perl'])
    blobs = read_blobs(entries)
    assert not subprocess.check_output(['git','ls-files','--others','--exclude-standard','-z','--','bin','perl'])
    members = {}
    for path, entry in entries.items():
        now = current_bytes(path)
        assert now == blobs[path], path + ' production restoration incomplete'
        members[path] = dict(bytes=len(now), sha256=sha(now), **entry)
    write_json(BASE / 'production-inventory.json', dict(baseline=BASELINE, changed_existing=[], added=[], members=members))
    (BASE / 'production-inventory.zlist').write_bytes(raw)
    old = json.loads(Path('docs/audits/conditional-macro-intent-20261002/immutable-parents.json').read_text())
    roots = old['roots'] + ['docs/audits/conditional-macro-intent-20261002']
    raw, entries = tree(BASELINE, roots)
    blobs = read_blobs(entries)
    members = {}
    for path, entry in entries.items():
        now = current_bytes(path)
        assert now == blobs[path], path + ' immutable predecessor changed'
        members[path] = dict(bytes=len(now), sha256=sha(now), **entry)
    write_json(BASE / 'immutable-parents.json', dict(baseline=BASELINE, roots=roots, members=members))
    (BASE / 'immutable-parents.zlist').write_bytes(raw)
    for source in Path('docs/audits/conditional-macro-intent-20261002/sources').glob('*.isf'):
        target = BASE / 'macro-sources' / source.name
        target.parent.mkdir(exist_ok=True)
        target.write_bytes(source.read_bytes())
    renders = {}
    markers = {
        '13b-transactions': "when activation body supports only '(sample port as name)' clauses",
        '13d-control-flow': 'A normalization candidate would newly admit',
        '13i-downstream-integration': 'the committed parser is restored',
        '13l-procedures': 'explicit source-intent prerequisite must qualify',
        '13k-isf-feature-support-matrix': 'source intent .5.2 must precede safe normalization',
    }
    for chapter, marker in markers.items():
        html = Path('docs/book/book/' + chapter + '.html')
        parser = Render()
        parser.feed(html.read_text())
        text = ' '.join(' '.join(parser.parts).split())
        assert marker in text, chapter + ' missing maintained text'
        if chapter == '13l-procedures':
            evidence = '../../../docs/audits/procedure-cond-normalization-20261002/scope.txt'
            assert evidence in parser.links and (html.parent/evidence).resolve() == (BASE/'scope.txt').resolve()
            assert '(actor acc_demo' in ''.join(parser.code)
        (BASE/(chapter+'.html')).write_bytes(html.read_bytes())
        renders[chapter] = dict(sha256=sha(html.read_bytes()), visual_browser_qa=False)
    wrapper = Path('docs/book/src/13i-downstream-integration.md').read_text()
    includes = [line.split('/')[3].split('}')[0] for line in wrapper.splitlines() if line.startswith('{{#include')]
    assert includes == ['10-downstream-readiness-source.md','11-downstream-actor-transactions.md','12-downstream-rules-artifacts-reports.md','13-downstream-diagnostics-conformance.md']
    write_json(BASE/'render.json', dict(chapters=renders, canonical_includes=includes))
    print('PASS complete terminal evidence, restored production, immutable predecessors and rendered text/code/links')


def seal():
    assert not (BASE/'manifest.json').exists(), 'sealed archive is immutable'
    entries = {str(p.relative_to(BASE)): dict(bytes=p.stat().st_size, sha256=sha(p.read_bytes())) for p in BASE.rglob('*') if p.is_file() and p.name!='manifest.json'}
    write_json(BASE/'manifest.json', dict(baseline=BASELINE, owner='SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.4.1', entries=entries))
    print('PASS sealed exact member census; archive now immutable')


if __name__=='__main__':
    {'collect':collect,'seal':seal}[sys.argv[1]]()
'''
(out/'seal.py').write_text(prefix+suffix)
