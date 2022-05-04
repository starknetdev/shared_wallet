import pytest


@pytest.fixture
def test_is_owner(my_contract, owner, other):
    my_contract.set_owner(sender=owner)
    assert owner == my_contract.owner()

    other_is_owner = my_contract.foo(sender=other)
    assert not other_is_owner
