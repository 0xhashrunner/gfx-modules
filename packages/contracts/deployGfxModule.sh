source .env.local

if [ -z "$CHAIN_NAME" ]; then
  echo "CHAIN_NAME is not set"
  exit 1
fi

# NOTE: Add your GFX Module contract name
CONTRACT_NAME="HypercastleZones" 

DEPLOY_OUTPUT="deploys/$CHAIN_NAME/$CONTRACT_NAME.json"
mkdir -p $(dirname $DEPLOY_OUTPUT)

if [ ! -f $DEPLOY_OUTPUT ] || [ ! -s $DEPLOY_OUTPUT ]; then
  forge create $CONTRACT_NAME --json --rpc-url=$RPC_URL --private-key=$DEPLOYER_PRIVATE_KEY | jq . > $DEPLOY_OUTPUT
fi

CONTRACT_ADDRESS=$(cat $DEPLOY_OUTPUT | jq -r ".deployedTo")
if [ -z $CONTRACT_ADDRESS ]; then
  echo "No contract address found in $DEPLOY_OUTPUT"
  exit 1
fi

echo "Using $CHAIN_NAME contract address: $CONTRACT_ADDRESS"

# NOTE: update to your GFX Module Path:Name
forge verify-contract \
  --chain-id $CHAIN_ID \
  --num-of-optimizations 200 \
  --watch \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --compiler-version $COMPILER_VERSION \
  $CONTRACT_ADDRESS \
  packages/contracts/src/gfxModules/HypercastleZones/HypercastleZones.sol:HypercastleZones
