from brownie import accounts, config, network, exceptions, interface
from scripts.deploy import deploy_contracts
from scripts.helpful_scripts import get_account, INITIAL_VALUE, DECIMALS
import time

FIRST_ALLOC = 10 ** 6
TOKEN_PRICE = 5  # in cents (cant be decimal!!!)


def test_sale():
    account = get_account()
    token, sale = deploy_contracts()

    josh_token_contract = interface.JoshTokenInterface(token.address)
    approve_tx = josh_token_contract.approve(
        sale.address, FIRST_ALLOC, {"from": account}
    )
    approve_tx.wait(1)

    print(f"ethPrice {sale.getEthPrice()}")

    tx = sale.startSale(FIRST_ALLOC, TOKEN_PRICE, {"from": account})  # 0.05$ / TOKEN
    tx.wait(1)

    assert sale.tokenPrice() == TOKEN_PRICE, "Price for token not equal to 0.05$"

    assert sale.getSaleAllowance() == FIRST_ALLOC, "Allowance not equal allocation!"

    """
        msg.value is amount in wei
        I send 1 ETH -> msg.value = 1e18
    """

    tx = sale.buyTokens(
        {"from": accounts[1], "value": 1 * 10 ** 18}
    )  # buying for 0.01 ETH, should get 0.01*INTIAL_PRICE/TOKEN_PRICE
    tx.wait(1)
    time.sleep(5)

    print(josh_token_contract.balanceOf(accounts[1]))
    # assert (
    #     josh_token_contract.balanceOf(accounts[1])
    #     == 10 ** 18 * INITIAL_VALUE / TOKEN_PRICE / 10 ** 23
    # )

    # tx = sale.buyTokens(
    #     {"from": accounts[2], "value": 1 * 10 ** 18}
    # )  # buying for 1 ETH
    # tx.wait(1)

    # assert (
    #     josh_token_contract.balanceOf(accounts[2])
    #     == 10 ** 18 * INITIAL_VALUE / TOKEN_PRICE / 10 ** DECIMALS
    # )
