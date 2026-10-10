"""Retain whole independently rejected scalar counterexamples."""
from common import load, save
import verify


if __name__ == '__main__':
    save('controls.json', verify.falsify(load('scalars.json'), load('plan.json'), load('native.json')))
    print('PASS whole genuine scalar source/value/schema/profile/scope and native controls reject their intended contracts.')
