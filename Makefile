-include .env

.PHONY: all test deploy

build :; forge build

test :; forge test

coverage resume:; forge coverage --report debug > coverage.txt

install :; forge install cyfrin/foundry-devops@0.2.2 && forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 && forge install foundry-rs/forge-std@0.2.3 && forge install trasmissions11/solmate@v6.0.0

deploy-sepolia:
	@forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $(SEPOLIA_RPC) --account $(FOUNDRY_WALLET) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv