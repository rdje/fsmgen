"""Independently qualify every whole selected native regex result."""
from common import BASE, load, save
import oracle


save('native-proof.json',oracle.native(load('plan.json'),load('native.json'),(BASE/'native.pl').read_bytes()))
print('PASS independently reconstructed whole regex values, encoding, flags, headers and traces.')
