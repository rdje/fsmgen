from pathlib import Path
from html.parser import HTMLParser
import json,shutil
class Text(HTMLParser):
 def __init__(self):super().__init__();self.parts=[]
 def handle_data(self,data):self.parts.append(data)
b=Path('docs/audits/native-proxy-observation-archive-release-readback-equal-20260912');out=Path('.artifacts/tmp/native-proxy-release-readback-equal-book-20260912/book');log=Path('.artifacts/logs')/b.name
assert (log/'book.exit').read_bytes()==b'0\n';parser=Text();parser.feed((out/'16dc-vial-portable-verilator-runtime-measurement.html').read_text());text=' '.join(' '.join(parser.parts).split())
phrases=['The equal-reference partition passes 462 primary cases and 5,107 assertions: 10 releases succeed and 452 attempts reject.','release preserves their distinct original paths and native identities while they share an archived content file.','A failed reader closes before source handoff; a returned source follows its original consumer\'s cleanup.','The earlier strong-reference counterexample remains separately authenticated evidence and is excluded from this partition\'s totals.','rejects collapsed original identities, invented archive identities and incorrect retirement records','native-proxy-observation-archive-release-readback-equal-20260912/audit.py --verify-saved']
for phrase in phrases:assert phrase in text,phrase
nodes=[out,*out.rglob('*')];device=Path('.').stat().st_dev
assert all(not p.is_symlink() and p.stat().st_dev==device and (p.is_file() or p.is_dir()) for p in nodes)
files=[p for p in nodes if p.is_file()];dirs=[p for p in nodes if p.is_dir()];stderr=(log/'book.stderr').read_text();warnings=[l.strip() for l in stderr.splitlines() if 'WARN' in l]
r=dict(exit_code=0,output=str(out),checked_passages=phrases,rendered_files=len(files),rendered_directories=len(dirs),rendered_bytes=sum(p.stat().st_size for p in files),same_volume_direct_objects=True,renderer_warnings=warnings)
shutil.rmtree(out);out.parent.rmdir();(log/'book.stdout').unlink();(log/'book.stderr').unlink();r['exact_output_absent']=not out.exists();(b/'book-review.json').write_text(json.dumps(r,sort_keys=True,indent=2)+'\n');print(json.dumps(r,sort_keys=True))
