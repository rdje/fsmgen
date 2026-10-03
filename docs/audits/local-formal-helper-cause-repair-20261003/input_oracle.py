# Independent literal input reconstruction retained from qualified diagnosis.
selected_source=products['select']['source'];header=selected_source.split('(transaction main ',1)[0]
ports=selected_source[len(header+'(transaction main '):selected_source.index(' (on start)')]
body='(transaction main '+ports+' (on start) (select result allow payload other) (complete done)))'
domain='(actor domains (clock-domains (domain core (clock clk) :default))(interface (input start) (input allow) (input payload (width 3)) (input other (width 3)) (output result (width 3)) (output done))'+body
expected_inputs={'equal-body origin transplant':{'api':'validate','authority_source':selected_source,'authority_label':'select.isf','context':products['authored']['context'],'proof':products['authored']['proof']}}
for name,cls in (('actual clone callback lost','DropClone'),('actual Storable callback lost','DropStorable')):
    expected_inputs[name]={'api':'from_source','class':'FSM::Test::LocalFormalOriginAuthority::'+cls,'source':selected_source,'label':'select.isf'}
for name,source_value,label in (
    ('imported producer boundary','(library lib (actor worker (transaction run (wait 1))))'+header+'(imports (library lib as imported))'+body,'imports.isf'),
    ('actor network boundary',header+'(instance remote of external_worker)'+body,'network.isf'),
    ('generated transaction boundary',header+'(transaction worker (params (MODE 1)) (wait 1))'+'(transaction main '+ports+' (on start) (do worker (params (MODE 1))) (select result allow payload other) (complete done)))','generated.isf'),
    ('domain constructor boundary',domain,'domain.isf'),
    ('no formal preparation boundary',header+'(transaction main (on start) (select result allow payload other) (complete done)))','plain.isf')):
    expected_inputs[name]={'api':'from_source','class':'FSM::Test::LocalFormalOriginAuthority','source':source_value,'label':label}
positive_inputs=json.loads((PRIOR/'positive_inputs.json').read_text());assert enc(positive_inputs)==enc(expected_inputs)
