"""Observe original static census phases; never write or accept an inventory."""
import json
import resource
import sys
import time

import runtime_inventory as original


def mark(phase, event, member=None):
    assert sys.platform == 'darwin', 'ru_maxrss units are explicitly Darwin bytes'
    print(json.dumps(dict(phase=phase, event=event, member=member,
                          monotonic_ns=time.monotonic_ns(),
                          self_maxrss_bytes=resource.getrusage(resource.RUSAGE_SELF).ru_maxrss),
                     sort_keys=True), flush=True)


def observe(module, name, member=False):
    function = getattr(module, name)

    def wrapped(*args, **kwargs):
        label = args[1] if member else None
        mark(name, 'enter', label)
        result = function(*args, **kwargs)
        mark(name, 'return', label)
        return result

    setattr(module, name, wrapped)


if __name__ == '__main__':
    # Instrument calls, preserving every original input, result and exception.
    # High-water observations describe this diagnostic process, not the prior
    # failed process, a live allocation size, or a global peak between samples.
    observe(original.selected_checkout, 'selection')
    observe(original, 'python_sites', member=True)
    observe(original.prepare, 'encoded')
    observe(original, 'validate')
    observe(original, 'controls')
    mark('build', 'enter')
    value = original.build()
    mark('build', 'return')
    original.validate(value, value)
    original.controls(value)
    mark('diagnostic', 'return')
