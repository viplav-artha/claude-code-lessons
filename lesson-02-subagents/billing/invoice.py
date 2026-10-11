from utils.formatting import currency

# NOTE: this is a teaching/demo stub. There is no real pricing/line-item
# lookup yet — every invoice uses the same placeholder amount. Replace
# _PLACEHOLDER_AMOUNT with an actual lookup (e.g. order/cart total for
# `user_id`) before using this for anything real.
_PLACEHOLDER_AMOUNT = 42.5


def make_invoice(user_id):
    """Build a simple invoice dict for the given user.

    Args:
        user_id: Identifier of the user the invoice is for. Must be a
            non-empty str or int.

    Returns:
        dict with the user id and formatted total.

    Raises:
        TypeError: if user_id is not a str or int.
        ValueError: if user_id is empty/blank.
    """
    if not isinstance(user_id, (str, int)) or isinstance(user_id, bool):
        raise TypeError("user_id must be a str or int")
    if isinstance(user_id, str) and not user_id.strip():
        raise ValueError("user_id must not be empty")

    return {"user": user_id, "total": currency(_PLACEHOLDER_AMOUNT)}
