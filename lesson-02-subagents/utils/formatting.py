def currency(amount):
    """Format a numeric amount as a USD currency string, e.g. "$42.50"."""
    if isinstance(amount, bool) or not isinstance(amount, (int, float)):
        raise TypeError("amount must be an int or float")
    return "${:.2f}".format(amount)
