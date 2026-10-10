"""Bind selected public APIs to complete locally installed public documentation."""
from common import BASE, SCOPE, load, need, pin, same, save

CONTRACTS = {
    'qr-doc': ('perlop', 'https://perldoc.perl.org/5.34.0/perlop#Regexp-Quote-Like-Operators',
        ['qr/I<STRING>/msixpodualn', 'Returns a Perl value', 'normalized version of the original pattern']),
    're-doc': ('re', 'https://perldoc.perl.org/5.34.0/re#regexp_pattern($ref)',
        ['regexp_pattern($ref)', 'In list context it returns a two element list', 'modifiers used when the pattern was compiled']),
    'encoding-doc': ('utf8', 'https://perldoc.perl.org/5.34.0/utf8#Utility-functions',
        ['utf8::upgrade($string)', 'utf8::downgrade($string', 'utf8::is_utf8($string)', 'logical character sequence itself is unchanged']),
}


def derive():
    result={}
    for name,(topic,url,markers) in CONTRACTS.items():
        receipt=load('actual-public-'+name+'-1.json')
        need(receipt['command']==['perldoc','-u',topic] and type(receipt['status']) is int and receipt['status']==0
             and receipt['stderr']=='' and all(marker in ' '.join(receipt['stdout'].split()) for marker in markers),
             'whole public POD/API evidence: '+name)
        result[name]=dict(receipt=pin((BASE/('actual-public-'+name+'-1.json')).read_bytes()),url=url,markers=markers)
    return dict(contracts=result,scope=SCOPE,
        external_read='Required installed Perl interpreter and public POD are read-only toolchain dependencies. No provider implementation is inspected and no project data is written outside the repository volume.')


if __name__=='__main__':
    result=derive()
    if (BASE/'public-contracts.json').exists():
        need(same(result,load('public-contracts.json')),'whole immutable public API evidence')
    else:
        save('public-contracts.json',result)
    print('PASS complete selected public qr, regexp_pattern and encoding API evidence; original runtime unmeasured.')
