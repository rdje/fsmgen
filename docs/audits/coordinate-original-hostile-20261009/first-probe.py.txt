"""Exercise public own semantic-check interfaces before whole intervention qualification."""
import json
import runpy
from pathlib import Path

A=Path('docs/audits');BASE=A/'coordinate-original-hostile-20261009'
m=runpy.run_path(str(BASE/'mutations.py'))
raw=json.loads((m['CLASS']/'raw-product.json').read_bytes())
models=json.loads((m['CLASS']/'source-models.json').read_bytes())
matched=json.loads((m['MATCHING']/'matching.json').read_bytes())
functions=runpy.run_path(str(m['MATCHING']/'match.py'))
points=m['points'](raw,matched);pairs=m['forwarding'](models,raw)
first=points[0]
nested=next(p for p in points if any(p['key']==pair['parent'] and p['phase']==0 for pair in pairs))
load=next(p for p in points if p['kind']=='load')
frame=next(p for p in points if p['kind']=='frame')
results=[]
for label,point in [('origin',first),('forwarded-origin',nested),('frame',frame),('load',load)]:
 for field,value in [('line',max(point['selection']['all_line_alternatives'].values())+1),('path','borrowed.pl')]:
  changed,affected=m['mutate'](raw,point,field,value,models)
  qualified=m['prior'](models,changed)
  observer=m['intervention_observer'](matched['observer_qualification'],changed,qualified)
  try:
   functions['derive'](changed,matched['source_phases'],qualified,matched['expression_alternatives'],observer)
  except ValueError as error:
   m['need'](str(error).startswith('declared own caller coordinate: '),'intended coordinate predicate after complete predecessor pass: '+str(error))
   results.append({'kind':label,'field':field,'affected':affected,'prior':'PASS complete class/frame/argument semantics','refusal':str(error)})
  else:raise ValueError('false-green prototype coordinate')
print(json.dumps({'result':'PASS representative genuine coordinate interventions preserve complete predecessor meanings','controls':results},sort_keys=True))
