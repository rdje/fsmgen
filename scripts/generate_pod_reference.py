#!/usr/bin/env python3
"""Generate/check the repository-owned Perl reference, without loading FSM code."""

import argparse
from contextlib import contextmanager
import fcntl
import hashlib
from html import escape
from html.parser import HTMLParser
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import sys
import tempfile
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = Path('docs/book/src/perl-api')
MARKER = '.fsmgen-pod-reference.json'
TOOLS = ('scripts/generate_pod_reference.py', 'scripts/pod_api_render.pl',
         'scripts/lib/FSMGen/PodHTML.pm', 'docs/pod-reference.css',
         'docs/pod-api-entrypoints.json')
MODULE = re.compile(r'FSM/(?:[A-Za-z_]\w*/)*[A-Za-z_]\w*\.pm\Z', re.ASCII)
SHA = re.compile(r'[0-9a-f]{64}\Z')


class ReferenceError(RuntimeError):
    pass


def require(condition, message):
    if not condition:
        raise ReferenceError(message)


def encoded(value):
    return (json.dumps(value, sort_keys=True, ensure_ascii=True, indent=2) + '\n').encode()


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def local_path(root, relative):
    """Validate existing components before either reading or creating a path."""
    relative = Path(relative)
    require(not relative.is_absolute() and '..' not in relative.parts,
            f'Expected a repository-relative path: {relative}')
    current = root
    device = root.stat().st_dev
    for part in relative.parts:
        current /= part
        require(not current.is_symlink(), f'Symlink path refused: {relative}')
        if current.exists():
            require(current.stat().st_dev == device, f'Foreign volume refused: {relative}')
            require(not (current.is_dir() and (current / '.git').exists()),
                    f'Nested Git repository refused: {relative}')
    return current


def regular_files(root, relative):
    base = local_path(root, relative)
    require(base.is_dir(), f'Missing directory: {relative}')
    paths = []
    for directory, dirs, files in os.walk(base, followlinks=False):
        for name in sorted(dirs + files):
            path = Path(directory) / name
            rel = path.relative_to(root)
            local_path(root, rel)
            require(path.is_dir() or path.is_file(), f'Nonregular path refused: {rel}')
            require(name != '.git', f'Nested Git boundary refused: {rel}')
        paths.extend((Path(directory) / name).relative_to(root) for name in files)
    return sorted(paths)


def run_perl(root, arguments):
    result = subprocess.run(['perl', str(root / 'scripts/pod_api_render.pl'), *map(str, arguments)],
                            cwd=root, capture_output=True)
    require(result.returncode == 0,
            'POD renderer failed:\n' + result.stderr.decode('utf-8', errors='replace'))
    try:
        return json.loads(result.stdout)
    except (ValueError, UnicodeError) as error:
        raise ReferenceError('POD renderer returned invalid JSON') from error


def capture_inputs(root):
    sources = {}
    for path in regular_files(root, 'perl/FSM'):
        if path.suffix == '.pm':
            require(MODULE.fullmatch(path.relative_to('perl').as_posix()),
                    f'Invalid module path: {path}')
            sources[path.as_posix()] = local_path(root, path).read_bytes()
    require(sources, 'No repository-owned Perl modules found')
    tools = {path: local_path(root, path).read_bytes() for path in TOOLS}
    versions = run_perl(root, ['--versions'])
    versions['python'] = {'implementation': sys.implementation.name,
                          'implementation_version': list(sys.implementation.version),
                          'language_version': list(sys.version_info)}
    identity = {'schema': 1, 'sources': {p: digest(v) for p, v in sources.items()},
                'tools': {p: digest(v) for p, v in tools.items()},
                'versions': versions}
    return sources, identity


@contextmanager
def generation_lock(root):
    locks = local_path(root, '.artifacts/locks')
    locks.mkdir(parents=True, exist_ok=True)
    path = local_path(root, '.artifacts/locks/pod-reference.lock')
    descriptor = os.open(path, os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
    try:
        try:
            fcntl.flock(descriptor, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as error:
            raise ReferenceError('Another POD reference generator is running') from error
        yield
    finally:
        os.close(descriptor)


class Page(HTMLParser):
    def __init__(self, text):
        super().__init__(convert_charrefs=True)
        self.anchors = set()
        self.links = []
        self.feed(text)
        self.close()

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        for name in ('id', 'name'):
            if attrs.get(name):
                self.anchors.add(attrs[name])
        for name in ('href', 'src'):
            if attrs.get(name):
                self.links.append(attrs[name])


def validate_links(output, book_source):
    pages = {p.resolve(): Page(p.read_text(encoding='utf-8'))
             for p in output.rglob('*.html')}
    for path, page in pages.items():
        for href in page.links:
            url = urlsplit(href)
            if url.scheme:
                require(url.scheme in ('https', 'http', 'mailto'), f'Unsafe URL: {href}')
                continue
            require(not url.netloc and not url.path.startswith('/') and '\\' not in href,
                    f'Nonrelative local URL: {href}')
            target = (path.parent / unquote(url.path)).resolve() if url.path else path
            if target.is_relative_to(output.resolve()):
                require(target.is_file(), f'Broken local link in {path.name}: {href}')
                if url.fragment:
                    require(target in pages and unquote(url.fragment) in pages[target].anchors,
                            f'Broken fragment in {path.name}: {href}')
            else:
                # The only permitted outbound local reference is the manual backlink.
                manual = (book_source / '11-extensions-and-embedding.md').resolve()
                require(not url.fragment and target.name == manual.with_suffix('.html').name
                        and target.parent == output.resolve().parent and manual.is_file(),
                        f'Local link escapes the reference: {href}')


def allowed_output(name):
    return name in ('index.html', 'coverage.html', 'coverage.json', 'reference.css') or bool(
        re.fullmatch(r'FSM/(?:[A-Za-z_]\w*/)*[A-Za-z_]\w*\.html', name, re.ASCII))


def output_hashes(root, relative):
    files = regular_files(root, relative)
    return {p.relative_to(relative).as_posix(): digest((root / p).read_bytes())
            for p in files if p.relative_to(relative).as_posix() != MARKER}


def inspect_existing(root, output):
    if not output.exists():
        return None, False
    marker = local_path(root, OUTPUT / MARKER)
    require(marker.is_file(), 'Refusing an unowned POD output directory (missing ownership manifest)')
    try:
        saved = json.loads(marker.read_bytes())
    except ValueError as error:
        raise ReferenceError('Invalid POD ownership manifest') from error
    require(isinstance(saved, dict) and type(saved.get('schema')) is int and saved['schema'] == 1
            and set(saved) == {'schema', 'inputs', 'outputs'}, 'Invalid POD manifest schema')
    expected = saved['outputs']
    require(isinstance(expected, dict) and expected
            and all(isinstance(p, str) and allowed_output(p) and isinstance(v, str)
                    and SHA.fullmatch(v) for p, v in expected.items()),
            'Unsafe output membership in POD manifest')
    actual = output_hashes(root, OUTPUT)
    require(not (set(actual) - set(expected)), 'Unowned extra files in POD output; refusing replacement')
    expected_dirs = {PurePosixPath(p).parent.as_posix() for p in expected}
    expected_dirs |= {q.as_posix() for p in expected for q in PurePosixPath(p).parents}
    for p in output.rglob('*'):
        if p.is_dir():
            require(p.relative_to(output).as_posix() in expected_dirs,
                    'Unowned extra directory in POD output; refusing replacement')
    return saved, actual == expected


def simple_page(title, body, prefix=''):
    return ('<!doctype html><html lang="en"><head><meta charset="utf-8">'
            '<meta name="viewport" content="width=device-width, initial-scale=1">'
            f'<title>{escape(title)}</title><link rel="stylesheet" href="{prefix}reference.css">'
            '</head><body><nav aria-label="Reference navigation">'
            f'<a href="{prefix}index.html">API index</a>'
            f'<a href="{prefix}../11-extensions-and-embedding.html">FSMGen manual</a>'
            f'</nav><main><h1>{escape(title)}</h1>{body}</main>'
            '<footer>Generated from repository POD with Pod::Simple::HTMLBatch.</footer></body></html>')


def render(root, work, sources):
    input_dir, output = work / 'input', work / 'output'
    output.mkdir()
    for path, raw in sources.items():
        target = input_dir / path.removeprefix('perl/')
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(raw)
    entrypoints = json.loads((root / 'docs/pod-api-entrypoints.json').read_bytes())
    modules = {p.removeprefix('perl/').removesuffix('.pm').replace('/', '::'): p for p in sources}
    require(isinstance(entrypoints, dict) and set(entrypoints) <= set(modules),
            'Selected entry point is absent from the source population')
    rows = run_perl(root, [input_dir, output, root / 'docs/pod-api-entrypoints.json'])
    require([r['module'] for r in rows] == sorted(modules), 'Renderer source population mismatch')
    coverage = []
    for row in rows:
        module, provided = row['module'], row['pod']
        path = module.replace('::', '/') + '.html'
        page = output / path
        role = 'selected_entry_point' if module in entrypoints else 'implementation'
        coverage.append({'module': module, 'source': modules[module], 'pod': provided, 'role': role})
        if not provided:
            page.parent.mkdir(parents=True, exist_ok=True)
            page.write_text(simple_page(module, '<p class="boundary">No POD is available for this module. '
                            'This inventory entry does not document its methods or promise an external API.</p>'
                            f'<p class="source">Source: <code>{modules[module]}</code></p>',
                            '../' * (len(module.split('::')) - 1)), encoding='utf-8')
        require(page.is_file(), f'POD page missing for {module}')
    body = ('<p>Every .pm source under perl/FSM is listed below. POD presence is a syntax/coverage '
            'observation; it does not prove semantic completeness or interface stability.</p><ul>'
            + ''.join(f'<li><a href="{r["module"].replace("::", "/")}.html">{r["module"]}</a> — '
                      f'{"POD provided" if r["pod"] else "no POD"}; {r["role"]}</li>' for r in coverage)
            + '</ul><p><a href="coverage.json">Machine-readable coverage</a></p>')
    (output / 'coverage.html').write_text(simple_page('POD coverage', body), encoding='utf-8')
    (output / 'coverage.json').write_bytes(encoded(coverage))
    shutil.copyfile(root / 'docs/pod-reference.css', output / 'reference.css')
    expected = {'index.html', 'coverage.html', 'coverage.json', 'reference.css'} | {
        m.replace('::', '/') + '.html' for m in modules}
    actual = {p.relative_to(output).as_posix() for p in output.rglob('*') if p.is_file()}
    require(actual == expected, f'Unexpected renderer output membership: {sorted(actual ^ expected)}')
    validate_links(output, root / 'docs/book/src')
    require(all(str(root).encode() not in p.read_bytes() for p in output.rglob('*') if p.is_file()),
            'Private checkout path leaked into POD output')
    return output


def generate(root=ROOT, *, check=False, repair=False):
    root = root.resolve()
    with generation_lock(root):
        output = local_path(root, OUTPUT)
        sources, identity = capture_inputs(root)
        saved, intact = inspect_existing(root, output)
        if saved and intact and saved['inputs'] == identity:
            validate_links(output, root / 'docs/book/src')
            return 'current'
        require(not check, 'POD reference is missing, stale or incomplete; regenerate it')
        require(not saved or intact or repair,
                'POD output is incomplete or modified; inspect it, then use --repair for owned files')
        temporary = local_path(root, '.artifacts/tmp')
        temporary.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='pod-reference-', dir=temporary) as name:
            work = Path(name)
            staged = render(root, work, sources)
            require(capture_inputs(root)[1] == identity, 'POD inputs changed during generation; retry')
            hashes = output_hashes(root, staged.relative_to(root))
            (staged / MARKER).write_bytes(encoded({'schema': 1, 'inputs': identity, 'outputs': hashes}))
            # Recheck ownership just before replacement. Never remove an unowned tree.
            require(inspect_existing(root, output) == (saved, intact), 'POD output changed during generation')
            previous = work / 'previous'
            if output.exists():
                output.rename(previous)
            try:
                output.parent.mkdir(parents=True, exist_ok=True)
                staged.rename(output)
            except OSError:
                if previous.exists():
                    previous.rename(output)
                raise
        return 'generated'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='check freshness/integrity without rendering')
    parser.add_argument('--repair', action='store_true', help='replace damaged manifest-owned files; refuse extras')
    args = parser.parse_args()
    require(not (args.check and args.repair), '--check and --repair are mutually exclusive')
    print('pod-reference: ' + generate(check=args.check, repair=args.repair))


if __name__ == '__main__':
    try:
        main()
    except (ReferenceError, OSError, ValueError) as error:
        print(f'pod-reference: ERROR: {error}', file=sys.stderr)
        sys.exit(1)
