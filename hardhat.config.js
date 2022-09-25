require("@nomiclabs/hardhat-waffle");

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 1337,
    },
    //  unused configuration commented out for now
    // mumbai: {
    //   url: "https://rpc-mumbai.maticvigil.com",
    //   accounts: [process.env.PRIVATE_KEY],
    // },
    // matic: {
    //   url: "https://rpc-mumbai.maticvigil.com",
    //   accounts: [
    //     process.env.PRIVATE_KEY
    //   ],
    // },
    // optimism: {
    //   url: "https://mainnet.optimism.io",
    //   accounts: [process.env.PRIVATE_KEY],
    // },
    goerli: {
      url: "https://rpc.ankr.com/eth_goerli",
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};
