"""Inactive preparation-layout selection, deliberately separate from validation.

Returning a layout name does not authorize an executable. The next owned codec
must validate statuses, source identities, complete references and cleanup.
"""


def select_layout(record, contracts):
    if type(record) is not dict or type(record.get("schema")) is not str:
        raise ValueError("expected an explicitly versioned preparation object")
    preparation = contracts["preparation"]
    schema = record["schema"]
    if schema == preparation["legacy_schema"]:
        fields = preparation["legacy_fields"]
        families = {"perl": "selected_perl_v1", "native": "legacy_private_native_v1"}
    elif schema == preparation["native_schema"]:
        fields = preparation["native_fields"]
        families = {"native": "shared_native_v2"}
    else:
        raise ValueError("unknown preparation version")
    if set(record) != set(fields):
        raise ValueError("preparation fields disagree with the explicit version")
    implementation = record["implementation"]
    if schema == preparation["legacy_schema"] and implementation is None:
        if type(record["ok"]) is int and record["ok"] == 0 and record["executable"] is None:
            return "unselected_failure_v1"
        raise ValueError("unselected legacy layout requires a non-runnable failure")
    if type(implementation) is not str or implementation not in families:
        raise ValueError("implementation is not part of this version")
    return families[implementation]
