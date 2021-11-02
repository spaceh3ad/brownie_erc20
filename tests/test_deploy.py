from brownie import accounts, config, network, exceptions, interface, Contract
from scripts.deploy import deploy_contracts
from scripts.helpful_scripts import get_account, fund_with_link
import time

FIRST_ALLOC = 10 ** 6 * 10 ** 18
TOKEN_PRICE = 5  # in cents (cant be decimal!!!)


def test_sale():
    accounts = get_account()
    print(accounts)
    token, sale = deploy_contracts()

    josh_token_contract = interface.JoshTokenInterface(token.address)
    approve_tx = josh_token_contract.approve(
        sale.address, FIRST_ALLOC, {"from": accounts[0]}
    )
    approve_tx.wait(1)

    print(f"ethPrice {sale.getEthPrice()}")

    tx = sale.startSale(
        FIRST_ALLOC, TOKEN_PRICE, {"from": accounts[0]}
    )  # 0.05$ / TOKEN
    tx.wait(1)

    assert sale.tokenPrice() == TOKEN_PRICE, "Price for token not equal to 0.05$"

    assert sale.getSaleAllowance() == FIRST_ALLOC, "Allowance not equal allocation!"

    """
        msg.value is amount in wei
        I send 1 ETH -> msg.value = 1e18
    """

    tx = sale.buyTokens({"from": accounts[1], "value": 4 * 10 ** 17})
    tx.wait(1)
    time.sleep(5)

    tx = sale.buyTokens({"from": accounts[2], "value": 15 * 10 ** 16})
    tx.wait(1)
    time.sleep(5)

    tx = sale.buyTokens({"from": accounts[3], "value": 2 * 10 ** 17})
    tx.wait(1)
    time.sleep(5)

    tx = fund_with_link(sale.address)
    tx.wait(1)

    # tx = sale.endSale({"from": accounts[0]})
    # tx.wait(1)
    # print(sale.sale_state())
    # time.sleep(20)
    # print(sale.recentWinner())

    # print(josh_token_contract.balanceOf(accounts[1]))
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
