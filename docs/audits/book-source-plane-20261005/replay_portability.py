"""Move an owned same-volume source plane and verify unchanged relative endpoints."""
import hashlib
import importlib.util
import json
import os
import shutil
from pathlib import Path

BASE=Path('docs/audits/book-source-plane-20261005')


def census(root):
    return {str(p.relative_to(root)):({'link':os.readlink(p)} if p.is_symlink() else {'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}) for p in root.rglob('*') if p.is_file() or p.is_symlink()}


def main():
    spec=importlib.util.spec_from_file_location('portable_book_plane','scripts/book_source_references.py')
    plane=importlib.util.module_from_spec(spec);spec.loader.exec_module(plane)
    first=BASE/'portability-first';moved=BASE/'portability-moved'
    assert not first.exists() and not moved.exists();first.mkdir()
    plane.ROOT=first.resolve();(first/'canonical').mkdir()
    (first/'canonical/source.md').write_text('# Complete source\n\nRelative endpoints survive a root move.\n')
    rows=[{'chapter':'90-reference-map','role':'retained-engineering-evidence','source':'canonical/source.md','asset':plane.asset_for('canonical/source.md')}]
    plane.write(rows);plane.check(rows)
    before=census(first);before_device=first.stat().st_dev;first.rename(moved)
    plane.ROOT=moved.resolve();plane.check(rows);after=census(moved)
    assert before==after and moved.stat().st_dev==before_device and not first.exists()
    result={'before':before,'after':after,'same_volume':True,'relative_root_before':str(first),'relative_root_after':str(moved),'source':(moved/'canonical/source.md').read_text(),'scope':'Actual move of an owned fixture inside this repository; no second Git repository, foreign write or production source mutation.'}
    target=BASE/'final-portability-proofs.json';assert not target.exists();target.write_text(json.dumps(result,sort_keys=True,indent=2)+'\n')
    assert moved.parent==BASE and moved.name=='portability-moved';shutil.rmtree(moved);assert not moved.exists()
    print('PASS actual same-volume fixture-root move preserves every source hash and relative endpoint; scoped source checks pass at the new root.')


if __name__=='__main__':main()
