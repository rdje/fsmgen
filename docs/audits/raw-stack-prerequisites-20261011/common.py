"""Full raw prerequisite scope and deterministic data helpers."""
import hashlib
import json
from pathlib import Path

BASE=Path('docs/audits/raw-stack-prerequisites-20261011')
REVISION='e42845fc43a61b2da76d5ad3fb5b4158c80765ff'
OWNER='SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.5.1'
RAW=OWNER.rsplit('.',2)[0]
CLASS=RAW+'.2'
OBSERVER=CLASS+'.3'
SCOPE=('Complete unchanged raw-stack prerequisites and observer/class-frame predecessor acceptance only. '
       'Whole original source/native/primary/class/frame/header/coordinate/address products and all dated/current evidence roles conserve. '
       'No original native class/provider/hook/settings/encoding/private/identity measurement, full raw semantic join, cause/consumer/alias/cold/permanent/host-native/visual/HIAL/CI/push closure is supplied.')


def need(condition,cause):
    if not condition:raise ValueError(cause)


def canonical(value):
    return (json.dumps(value,sort_keys=True,separators=(',',':'),ensure_ascii=True,allow_nan=False)+'\n').encode()


def pin(raw):return dict(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())


def load(name):return json.loads((BASE/name).read_bytes())


def save(name,value):
    path=BASE/name;need(not path.exists(),'retain complete first raw prerequisite evidence: '+name)
    path.write_bytes(canonical(value))
