"""Rebuild the complete qualified source model before new header hypotheses."""
from common import BASE, SOURCE, module, need, same, save
import json
from pathlib import Path


def main():
    classes = module(Path('docs/audits/record-value-original-class-20261005/verify.py'))
    public = module(Path('docs/audits/record-value-public-boundary-join-20261006/verify.py'))
    model = module(SOURCE / 'model.py')
    expected = model['derive'](classes, public, classes['require'], classes['same'])
    need(same(expected, json.loads((SOURCE / 'source-models.json').read_bytes())),
         'entire independently rederived qualified source model')
    save('source-models.json', expected)
    print('PASS complete qualified source model independently rederived; inherited inner evidence and original opaque scopes retain.')


if __name__ == '__main__':
    main()
