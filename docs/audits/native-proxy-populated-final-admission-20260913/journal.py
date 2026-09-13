"""Bounded exclusive controller journal with retained failed-write context."""
import os
import time

from contract import ROOT, OUTPUT, bounds, canonical
import local_files as files
import records


class Journal:
    def __init__(self):
        self.path = OUTPUT + '/journal.jsonl'
        self.limits, self.prefix = bounds(), bytearray()
        self.count, self.failed, self.descriptor = 0, None, None
        self.origin = time.monotonic_ns()

    def open(self):
        if self.descriptor is not None or self.count or self.failed is not None:
            raise ValueError('journal open is one use')
        files.directory_identity(OUTPUT)
        self.descriptor = os.open(ROOT / self.path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW | os.O_CLOEXEC, 0o600)

    def __call__(self, event, **fields):
        if self.failed is not None or self.descriptor is None:
            raise ValueError('journal is unavailable; owned recovery required')
        try:
            if set(fields) & {'event', 'sequence', 'elapsed_ns'}:
                raise ValueError('journal fields replace the controller envelope')
            elapsed = records.integer(time.monotonic_ns() - self.origin)
            row = dict(event=event, sequence=self.count, elapsed_ns=elapsed, **fields)
            body = canonical(row) + b'\n'
            if self.count >= self.limits['journal_events'] or len(self.prefix) + len(body) > self.limits['journal_bytes']:
                raise ValueError('controller journal bound exceeded')
            # Keep the whole bounded intended row before any partial OS write.
            # Recovery can preserve it separately; it is never a success record
            # for a write that did not complete.
            self.prefix.extend(body)
            files.write_all(self.descriptor, body)
            self.count += 1
        except BaseException as error:
            self.failed = dict(type=type(error).__name__, message=str(error))
            raise

    def close(self):
        if self.descriptor is not None:
            descriptor, self.descriptor = self.descriptor, None
            try:
                files.close_descriptor(descriptor)
            except OSError as error:
                if self.failed is None:
                    self.failed = dict(type=type(error).__name__, message=str(error))
                raise
        return dict(path=self.path, completed_rows=self.count, intended_prefix=records.file_pin(self.prefix), first_failure=self.failed)

    def preserve_failed_prefix(self):
        if self.failed is None:
            raise ValueError('only a failed journal has a recovery prefix')
        return files.write_bytes(OUTPUT + '/journal-recovery.jsonl', bytes(self.prefix), 0o400, self.limits['journal_bytes'])
