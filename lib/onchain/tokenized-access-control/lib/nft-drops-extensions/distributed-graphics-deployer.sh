
function create() {
  SHARED_NFT_LOGIC=0xbd677ce2635bab1041931e742d0984fadae44c41
  TARGET=src/distributed-graphics-editions/DistributedGraphicsEdition.sol:DistributedGraphicsEdition
  forge create $TARGET -i --rpc-url https://rinkeby.infura.io/v3/406a91f7df014ede94214f012cca2317 --constructor-args $SHARED_NFT_LOGIC
}

function verify() {
  TARGET_ADDR=0x9d834538cba7e8f239d93d22e547f4966e881e7a
  SHARED_NFT_LOGIC=0xbd677ce2635bab1041931e742d0984fadae44c41
  TARGET=src/distributed-graphics-editions/DistributedGraphicsEdition.sol:DistributedGraphicsEdition
  ARGS=$(cast abi-encode "a(address)" $SHARED_NFT_LOGIC)
  echo $ARGS
  forge verify-contract --chain-id 4 $TARGET_ADDR $TARGET_CONTRACT F3CECMYDCKR5SNEF1NSH46BF8VQWN3HAGXt
}


function create_mainnet() {
  SHARED_NFT_LOGIC=0x7eB947242dbF042e6388C329A614165d73548670
  TARGET=src/distributed-graphics-editions/DistributedGraphicsEdition.sol:DistributedGraphicsEdition
  forge create $TARGET -i --rpc-url https://mainnet.infura.io/v3/406a91f7df014ede94214f012cca2317 --constructor-args $SHARED_NFT_LOGIC
}

function verify_mainnet() {
  TARGET_ADDR=0x35ca784918bf11692708c1d530691704aacea95e
  SHARED_NFT_LOGIC=0x7eB947242dbF042e6388C329A614165d73548670
  TARGET_CONTRACT=src/distributed-graphics-editions/DistributedGraphicsEdition.sol:DistributedGraphicsEdition
  ARGS=$(cast abi-encode "a(address)" $SHARED_NFT_LOGIC)
  forge verify-contract --constructor-args 0000000000000000000000007eb947242dbf042e6388c329a614165d73548670 --chain mainnet $TARGET_ADDR $TARGET_CONTRACT F3CECMYDCKR5SNEF1NSH46BF8VQWN3HAGXt
}