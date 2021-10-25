from brownie import (
    JoshToken,
    JoshTokenSale,
    MockV3Aggregator,
    config,
    network,
)
from scripts.helpful_scripts import (
    get_account,
    get_contract,
    LOCAL_BLOCKCHAIN_ENVIROMENTS,
    deploy_mocks,
)
from web3 import Web3

INITIAL_SUPPLY = 10 * 10 ** 6
TOKEN_PRICE = 20  # cents


def deploy_token():
    account = get_account()
    token = JoshToken.deploy(
        INITIAL_SUPPLY,
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify", False),
    )
    print(f"Deployed JoshToken at: {token}")
    return token


def approve_sale(token):
    account = get_account()
    token.approve({"from":account})


def deploy_sale(token):
    account = get_account()
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIROMENTS:
        price_feed_address = config["networks"][network.show_active()][
            "eth_usd_price_feed"
        ]
    else:
        deploy_mocks()
        price_feed_address = MockV3Aggregator[-1].address

    sale = JoshTokenSale.deploy(token.address, price_feed_address, {"from": account})
    print(f"Deployed JoshTokenSale at: {sale}")
    return sale


def get_eth_price(sale):
    eth_price = sale.getEthPrice()
    print(f"{eth_price = }")
    # getEthPrice


def main():
    token = deploy_token()
    approve_sale(token)
    sale = deploy_sale(token)
    get_eth_price(sale)
