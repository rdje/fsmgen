"""Execute the unchanged complete historical qualifier at its committed epoch."""
import hashlib
import json
import os
import shutil
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/record-value-coordinate-admission-20261007')
REVISION = 'e0620dd2ffb04c340b91693a04f5885c8abb6595'
DESTINATION = Path('.artifacts/coordinate-publication-epoch')
COMMAND = ['python3', '-B', 'docs/audits/class-frame-publication-checks-20261006/verify_seal.py']


def identity(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def require(condition, cause):
    if not condition:
        raise ValueError(cause)


def extract():
    """Stream regular committed members into a new contained local fixture.

    Git archive never recurses into gitlink contents. This reads committed own
    files without inspecting or constructing foreign submodule implementations.
    The real Git object database is used read-only by the unchanged qualifier.
    """
    require(not DESTINATION.exists(), 'historical source fixture cannot replace a workspace')
    root = Path.cwd().resolve()
    require(DESTINATION.parent.is_dir() and not DESTINATION.parent.is_symlink()
        and DESTINATION.parent.resolve().parent == root
        and DESTINATION.parent.stat().st_dev == root.stat().st_dev, 'same-volume contained historical fixture')
    DESTINATION.mkdir()
    process = subprocess.Popen(['git', 'archive', REVISION], stdout=subprocess.PIPE)
    members = {}
    try:
        with tarfile.open(fileobj=process.stdout, mode='r|') as archive:
            for entry in archive:
                path = Path(entry.name)
                require(not path.is_absolute() and '..' not in path.parts and '.git' not in path.parts,
                        'contained own committed source path')
                output = DESTINATION / path
                if entry.isdir():
                    output.mkdir(parents=True, exist_ok=True)
                elif entry.isfile():
                    raw = archive.extractfile(entry).read()
                    output.parent.mkdir(parents=True, exist_ok=True)
                    require(not output.exists(), 'unique whole historical archive member')
                    output.write_bytes(raw)
                    output.chmod(entry.mode)
                    members[str(path)] = identity(raw)
                elif entry.issym():
                    # Preserve links as opaque Git entries, without reading
                    # their targets. The scoped qualifier must never use them.
                    output.parent.mkdir(parents=True, exist_ok=True)
                    output.symlink_to(entry.linkname)
                    members[str(path)] = dict(kind='opaque-symlink', target=entry.linkname)
                else:
                    raise ValueError('unsupported committed historical source entry')
    except BaseException:
        process.terminate()
        raise
    finally:
        process.stdout.close(); process.wait()
    require(process.returncode == 0, 'actual complete historical source archive success')
    return members


def census():
    result = {}
    for path in sorted(DESTINATION.rglob('*')):
        name = str(path.relative_to(DESTINATION))
        if path.is_symlink():
            result[name] = dict(kind='opaque-symlink', target=os.readlink(path))
        elif path.is_file():
            result[name] = identity(path.read_bytes())
        else:
            require(path.is_dir(), 'regular historical source fixture population')
    return result


def main():
    output = BASE / 'historical-epoch-actual.json'
    require(not output.exists(), 'historical actual result cannot overwrite evidence')
    members = extract()
    require(census() == members, 'complete original historical archive member bytes')
    root = Path.cwd().resolve()
    environment = os.environ.copy()
    environment.update(GIT_DIR=str(root / '.git'), GIT_WORK_TREE=str((root / DESTINATION).resolve()))
    # These are runtime-derived paths. No project configuration or persisted
    # path depends on the checkout's absolute location.
    execution = subprocess.run(COMMAND, cwd=DESTINATION, env=environment, capture_output=True, text=True)
    after = census()
    value = dict(revision=REVISION, destination=str(DESTINATION), command=COMMAND,
        status=execution.returncode, stdout=execution.stdout, stderr=execution.stderr,
        members=members, after_members=after, programme=identity(Path(__file__).read_bytes()),
        role='Fresh unchanged complete historical actual-result qualifier at its exact committed source epoch; original evidence retained and live publication bytes untouched. No later current currency.')
    output.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')
    require(type(execution.returncode) is int and execution.returncode == 0, 'historical epoch actual integer success')
    require(members == after, 'whole historical source epoch conserved across actual qualifier')
    require(execution.stderr == '', 'historical actual qualifier empty diagnostics')
    # Only this new, exactly inventoried disposable source fixture is removed.
    # Committed products and the real Git database are never cleanup targets.
    shutil.rmtree(DESTINATION)
    require(not DESTINATION.exists(), 'historical source fixture residue absent')
    print('PASS unchanged complete historical actual-result qualifier at its fixed committed epoch; live sources untouched and fixture residue absent.')


if __name__ == '__main__':
    main()
