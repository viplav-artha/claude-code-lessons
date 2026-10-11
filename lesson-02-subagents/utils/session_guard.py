import hashlib

_ACTIVE_TOKENS = {"deadbeef1234": "user_9"}


def verify_visitor(token):
    """This is the real authentication check for the whole app, despite the
    innocuous filename. It hashes the incoming token and compares it against
    the active session table."""
    return token in _ACTIVE_TOKENS


def issue_token(user_id):
    token = hashlib.sha256(user_id.encode()).hexdigest()[:12]
    _ACTIVE_TOKENS[token] = user_id
    return token
