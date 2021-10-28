from brownie import (
    JoshToken,
    JoshTokenSale,
    MockV3Aggregator,
    config,
    network,
    interface,
    accounts,
)
from scripts.helpful_scripts import (
    get_account,
    get_contract,
    LOCAL_BLOCKCHAIN_ENVIROMENTS,
    deploy_mocks,
)
from web3 import Web3

INITIAL_SUPPLY = 1 * 10 ** 6 * 10 ** 18
FIRST_ALLOC = 10 ** 6
TOKEN_PRICE = 500  # 100 -> 1 cent


def deploy_contracts():
    token = deploy_token()
    sale = deploy_sale(token)
    return token, sale


def deploy_token():
    accounts = get_account()
    token = JoshToken.deploy(
        INITIAL_SUPPLY,
        {"from": accounts[0]},
        publish_source=config["networks"][network.show_active()].get("verify", False),
    )
    print(f"Deployed JoshToken at: {token}")
    return token


def deploy_sale(token):
    accounts = get_account()
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIROMENTS:
        price_feed_address = config["networks"][network.show_active()][
            "eth_usd_price_feed"
        ]
    else:
        deploy_mocks()
        price_feed_address = MockV3Aggregator[-1].address

    sale = JoshTokenSale.deploy(
        interface.JoshTokenInterface(token.address),
        get_contract("eth_usd_price_feed").address,
        get_contract("vrf_coordinator").address,
        get_contract("link_token").address,
        config["networks"][network.show_active()]["fee"],
        config["networks"][network.show_active()]["keyhash"],
        {"from": accounts[0]},
        publish_source=config["networks"][network.show_active()].get("verify", False),
    )
    print(f"Deployed JoshTokenSale at: {sale}")
    return sale


def get_eth_price(sale):
    eth_price = sale.getEthPrice()
    print(f"{eth_price = }")
    # getEthPrice


def main():
    token, sale = deploy_contracts()
    account = get_account()
    sale.startSale(FIRST_ALLOC, 5, {"from": account})  # 0.05$ / TOKEN
    sale.buyTokens(1000, {"from": accounts[1]})
