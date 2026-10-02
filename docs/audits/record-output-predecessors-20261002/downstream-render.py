import hashlib,json
from html.parser import HTMLParser
from pathlib import Path
class View(HTMLParser):
 def __init__(self): super().__init__();self.ids=set();self.text=[];self.in_pre=False;self.pre=[];self.blocks=[]
 def handle_starttag(self,tag,attrs):
  a=dict(attrs)
  if 'id' in a:self.ids.add(a['id'])
  if tag=='pre':self.in_pre=True;self.pre=[]
 def handle_endtag(self,tag):
  if tag=='pre':self.blocks.append(''.join(self.pre));self.in_pre=False
 def handle_data(self,data):
  self.text.append(data)
  if self.in_pre:self.pre.append(data)
page=Path('docs/book/book/13i-downstream-integration.html').read_bytes();v=View();v.feed(page.decode())
source=Path('.artifacts/record-output-predecessors/downstream-record-ports.isf').read_text()
assert source.rstrip() in [b.rstrip() for b in v.blocks]
assert 'packed-record-actor-ports' in v.ids
assert 'Record source admission remains refused.' not in ''.join(v.text)
paths=['10-downstream-readiness-source.md','11-downstream-actor-transactions.md','12-downstream-rules-artifacts-reports.md','13-downstream-diagnostics-conformance.md']
chapter=Path('docs/book/src/13i-downstream-integration.md').read_text()
assert [line for line in chapter.splitlines() if line.startswith('{{#include')] == ['{{#include ../../isf-spec/'+p+'}}' for p in paths]
rows={p:{'sha256':hashlib.sha256(Path('docs/isf-spec',p).read_bytes()).hexdigest(),'text':Path('docs/isf-spec',p).read_text()} for p in paths}
work=Path('.artifacts/record-output-predecessors');(work/'downstream-render.html').write_bytes(page)
(work/'downstream-render.json').write_text(json.dumps({'chapter':chapter,'parts':rows,'example_matches_rendered_code':True,'record_heading_present':True,'old_refusal_absent':True,'render_sha256':hashlib.sha256(page).hexdigest()},indent=2)+'\n')
print('Canonical downstream includes, exact complete rendered record-port example and current source/report boundary pass; old blanket record refusal is absent.')
