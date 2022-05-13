"""Utilities for testing Cairo contracts."""
SHORT_STR_SIZE = 31

def to_uint(a):
    """Takes in value, returns uint256-ish tuple."""
    return (a & ((1 << 128) - 1), a >> 128)


def uint(a):
    return (a, 0)


def str_to_felt(text):
    b_text = bytes(text, "ascii")
    return int.from_bytes(b_text, "big")

def str_to_short_str_array(text):
    res = []
    for i in range(len(text)):
        temp = text[i:i+SHORT_STR_SIZE]
        res.append(str_to_felt(temp))
        i += SHORT_STR_SIZE
    return res


