const { expect } = require("chai")

describe("NFTMarket", function() {
  let nftMarketplace;
  let contractOwnerAddress, creatorAddress, buyerAddress;

  beforeEach(async function() {
    [contractOwnerAddress, creatorAddress, buyerAddress] = await ethers.getSigners()
    const PromiseLand = await ethers.getContractFactory("PromiseLand")
    nftMarketplace = await PromiseLand.deploy()
    await nftMarketplace.deployed()

    /* create tokens */
    await nftMarketplace.connect(creatorAddress).createToken("https://1.example.com")
    await nftMarketplace.connect(creatorAddress).createToken("https://2.example.com")
    await nftMarketplace.connect(creatorAddress).createToken("https://3.example.com")
    await nftMarketplace.connect(creatorAddress).createToken("https://4.example.com")
  });

  it("Should create and execute market sales", async function() {
    const auctionPrice = ethers.utils.parseEther('1')

    // list sales
    await nftMarketplace.connect(creatorAddress).updateListingPrice(1, auctionPrice)
    await nftMarketplace.connect(creatorAddress).updateListingPrice(2, auctionPrice)
    await nftMarketplace.connect(creatorAddress).updateListingPrice(3, auctionPrice)

    /* execute sale of token to another user */
    await nftMarketplace.connect(buyerAddress).executeSale(1, { value: auctionPrice })
    await nftMarketplace.connect(buyerAddress).executeSale(2, { value: auctionPrice })

    /* resell a token */
    await nftMarketplace.connect(buyerAddress).updateListingPrice(1, auctionPrice)

    /* query for and return the unsold items */
    const items = await nftMarketplace.fetchAllNfts().then((items) => Promise.all(items.map(async i => {
      const tokenUri = await nftMarketplace.tokenURI(i.tokenId)
      let item = {
        tokenId: i.tokenId.toString(),
        creator: i.creator,
        owner: i.owner,
        price: i.price.toString(),
        likes: i.likes.toString(),
        dislikes: i.dislikes.toString(),
        selling: i.selling,
        reselling: i.reselling,
        tokenUri
      }
      return item
    })))
    console.log('items: ', items)
  })

  it('Should able to like', async function() {
    const likingPrice = await nftMarketplace.likingPrice()

    await nftMarketplace.connect(buyerAddress).likeNft(1, { value: likingPrice })

    const token1 = await nftMarketplace.fetchNftById(1);
    expect(token1.likes.toNumber()).to.be.equal(1);
  })
})
