from brownie import (
    accounts,
    network,
    config,
    MockV3Aggregator,
    # VRFCoordinatorMock,
    # LinkToken,
    Contract,
    interface,
)
from web3 import Web3

FORKED_LOCAL_ENVIROMENTS = ["mainnet-fork", "mainnet-fork-dev"]
LOCAL_BLOCKCHAIN_ENVIROMENTS = ["development", "ganache-local"]


def get_account(index=None, id=None):
    if index:
        return accounts[index]
    if id:
        return accounts.load(id)
    if (
        network.show_active() in LOCAL_BLOCKCHAIN_ENVIROMENTS
        or network.show_active() in FORKED_LOCAL_ENVIROMENTS
    ):
        return accounts[0]
    return accounts.add(config["wallets"]["from_key"])


contract_to_mock = {"eth_usd_price_feed": MockV3Aggregator}


def get_contract(contract_name):
    """this function will grab contract addresses from brownie config if defined,
    otherwise it will deploy a mock contract and return mock contract

        Args:
            contrac_name [string]

        Returns:
            brownie.network.contract.ProjectContract: The most recently
            deployed version of this contract

    """
    contract_type = contract_to_mock[contract_name]
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIROMENTS:
        if len(contract_type) <= 0:
            deploy_mocks()
        contract = contract_type[-1]

    else:
        contract_address = config["networks"][network.show_active()][contract_name]
        contract = Contract.from_abi(
            contract_type._name, contract_address, contract_type.abi
        )
    return contract


DECIMALS = 8
INITIAL_VALUE = 48676618555


def deploy_mocks(decimals=DECIMALS, initial_value=INITIAL_VALUE):
    # 1 ETH ~ 4184 $
    account = get_account()
    MockV3Aggregator.deploy(decimals, initial_value, {"from": account})
    # link_token = LinkToken.deploy({"from": account})
    # VRFCoordinatorMock.deploy(link_token.address, {"from": account})


def fund_with_link(
    contract_address, account=None, link_token=None, amount=100000000000000000
):
    assert amount == Web3.toWei(0.1, "ether"), "Not sending 0.1 TOKEN"
    account = account if account else get_account()
    link_token = link_token if link_token else get_contract("link_token")
    assert account.balance() != 0, "Insufficient account balance"
    tx = link_token.transfer(contract_address, amount, {"from": account})
    # link_token_contract = interface.LinkTokenInterface(link_token.address)
    # tx = link_token_contract.transfer(contract_address, amount, {"from": account})
    tx.wait(1)
    print("Funded contract with LINK!")
    return tx
