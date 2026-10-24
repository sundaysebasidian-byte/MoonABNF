"""Pure, offline guards for local-candidate and registry consumer evidence."""
import hashlib
import re
from pathlib import Path


def registry_version(value):
    """An explicit release selection is not evidence that it exists or passed."""
    if not re.fullmatch(r'(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)', value):
        raise ValueError('Select an explicit stable release version (major.minor.patch).')
    if value == '0.1.0':
        raise ValueError('Published 0.1.0 lacks the input-tree API used by this consumer; '
                         'use its historical template, or select an approved newer release. '
                         'For unpublished code run scripts/downstream.py.')
    return value


def bind_candidate(archive, root):
    """Reject stale/mixed package sources before claiming local consumption."""
    required = {'moon.mod', 'moon.pkg', 'pkg.generated.mbti', 'input_tree.mbt',
                'compiler.mbt', 'parser.mbt', 'recognizer.mbt', 'types.mbt',
                'analysis.mbt', 'core.mbt'}
    entries = [info for info in archive.infolist() if not info.is_dir()]
    names = [info.filename for info in entries]
    if len(names) != len(set(names)):
        raise ValueError('Duplicate candidate archive members')
    if not required.issubset(names):
        raise ValueError('Candidate archive lacks required input-tree implementation files')
    hashes = {}
    root = Path(root).resolve()
    for name in sorted(names):
        path = Path(name)
        if path.is_absolute() or '..' in path.parts:
            raise ValueError('Unsafe candidate archive member')
        source = (root / path).resolve()
        if root not in source.parents or not source.is_file():
            raise ValueError('Candidate member has no source binding: ' + name)
        digest = hashlib.sha256(archive.read(name)).hexdigest()
        if hashlib.sha256(source.read_bytes()).hexdigest() != digest:
            raise ValueError('Candidate/source mismatch: ' + name)
        hashes[name] = digest
    return hashes


def require(condition, message):
    """Acceptance checks must survive python -O and PYTHONOPTIMIZE."""
    if not condition:
        raise RuntimeError(message)
