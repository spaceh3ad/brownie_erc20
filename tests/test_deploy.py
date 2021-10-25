from brownie import accounts, config, network, exceptions, interface
from scripts.deploy import deploy_contracts
from scripts.helpful_scripts import get_account

FIRST_ALLOC = 10 ** 6


def test_can_start_sale():
    account = get_account()
    token, sale = deploy_contracts()
    tx = sale.startSale(5, {"from": account})  # 0.05$ / TOKEN
    tx.wait(1)

    josh_token_contract = interface.JoshTokenInterface(token.address)
    approve_tx = josh_token_contract.approve(
        sale.address, FIRST_ALLOC, {"from": account}
    )
    approve_tx.wait(1)

    assert sale.tokenPrice() == 5, "Price for token not equal to 0.05$"

    # josh_token_contract = interface.JoshTokenInterface(token.address)
    # allowance = josh_token_contract.allowance(account, token.address)
    print(f" Allowance = { sale.getSaleAllowance()}")
    print("adadad")
    assert sale.getSaleAllowance() == FIRST_ALLOC, "Allowance not equal allocation!"

    tx = sale.buyTokens(100, {"from": accounts[1]})
    tx.wait(1)
    # print(sale)
    # josh_token_contract = interface.JoshTokenInterface(token.address)
    # [accounts[1]]

    # account = get_account()
    # sale = deploy_contracts()
    # sale_tx = sale.startSale(10 * 10 ** 6, 20, {"from": account})
    # sale_tx.wait(1)
    # assert sale.sale_state() == 0, "Sale state not OPEN"

    # tx = sale.buyTokens(100, {"from": accounts[1]})
    # tx.wait(1)
    # balance_account_1 = sale.balanceOf(accounts[1])
    # print(f"{balance_account_1 = }")
