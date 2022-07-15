const { expect } = require("chai");

describe("SmartGenerative contract", function () {
  let Token;
  let hardhatToken;
  let owner,addr1,addr2,addr3,addr4,addr5;

  beforeEach(async function () {
    Token = await ethers.getContractFactory("SmartGenerative");
    [owner, addr1, addr2, addr3,addr4,addr5] = await ethers.getSigners();

    hardhatToken = await Token.deploy();
  });

  // test info---
  describe("account test info display", async () => {
    it("account test", async () => {
      console.log("owner address : %s", owner.address);
      console.log("addr1 address : %s", addr1.address);
      console.log("addr2 address : %s", addr2.address);
      console.log("addr3 address : %s", addr3.address);
      console.log("addr4 address : %s", addr4.address);
      console.log("addr5 address : %s", addr5.address);
      console.log("owner value : %s", await owner.getBalance());
      console.log("addr1 value : %s", await addr1.getBalance());    //also addr2..
    });
  });
  //---

  describe("premint & mint paused",function(){
    it("Shoud paused",async function(){
      var array1 = new Array();
      await expect(
        hardhatToken.premint(1, array1)
        ).to.be.revertedWith("the contract is paused");

      await expect(
        hardhatToken.mint(1, array1)
        ).to.be.revertedWith("the contract is paused");
    }
    );
  });

  describe("premint require",function(){
    it("Shoud require",async function(){
      await hardhatToken.setOnlyWhitelisted(false);

      //require
      var array1 = new Array();
      await expect(
        hardhatToken.premint(0, array1)
        ).to.be.revertedWith("need to mint at least 1 NFT");
      
      await expect(
        hardhatToken.premint(6, array1)
        ).to.be.revertedWith("max mint amount per session exceeded");
        
      for(let i=0;i<200;i++){   //max mint
        await  hardhatToken.premint(5, array1);
      }
      await expect(
          hardhatToken.premint(1, array1)
          ).to.be.revertedWith("pre Sale NFT limit exceeded");
    }
    );
  })

  // MarkleTree in addr1,addr2,addr3,addr4
  // ref> https://play-nft.art/merkle_tree
  describe("WhiteList OK",function(){
    it("Shoud OK lead",async function(){
      await hardhatToken.setOnlyWhitelisted(false);
      await hardhatToken.setPresaleRoots("0x5c0965c65dfb1547d128efb3e61004f43995418da2d36870318fd1d53a6ec3ab");

      var array1 = new Array();
      array1.push("0x8a3552d60a98e0ade765adddad0a2e420ca9b1eef5f326ba7ab860bb4ea72c94");
      array1.push("0x28ee50ccca7572e60f382e915d3cc323c3cb713b263673ba830ab179d0e5d57f");

      const addr1Balance = await hardhatToken.balanceOf(addr1.address);
      expect(addr1Balance).to.equal(0);

      await hardhatToken.connect(addr1).premint(1,array1,{ value: ethers.utils.parseEther("0.5") });

      const addr1Balance_mint = await hardhatToken.balanceOf(addr1.address);
      expect(addr1Balance_mint).to.equal(1);
    }
    );
    it("Shoud OK last",async function(){
        await hardhatToken.setOnlyWhitelisted(false);
        await hardhatToken.setPresaleRoots("0x5c0965c65dfb1547d128efb3e61004f43995418da2d36870318fd1d53a6ec3ab");
  
        var array1 = new Array();
        array1.push("0x1ebaa930b8e9130423c183bf38b0564b0103180b7dad301013b18e59880541ae");
        array1.push("0x343750465941b29921f50a28e0e43050e5e1c2611a3ea8d7fe1001090d5e1436");
  
        const addr1Balance = await hardhatToken.balanceOf(addr4.address);
        expect(addr1Balance).to.equal(0);
  
        await hardhatToken.connect(addr4).premint(1,array1,{ value: ethers.utils.parseEther("0.5") });
  
        const addr1Balance_mint = await hardhatToken.balanceOf(addr4.address);
        expect(addr1Balance_mint).to.equal(1);
      }
      );
  });

  describe("WhiteList NG > unmuch _merkleProof",function(){
    it("Shoud NG",async function(){
      await hardhatToken.setOnlyWhitelisted(false);
      await hardhatToken.setPresaleRoots("0x5c0965c65dfb1547d128efb3e61004f43995418da2d36870318fd1d53a6ec3ab");

      var array1 = new Array();
//      array1.push("0x8a3552d60a98e0ade765adddad0a2e420ca9b1eef5f326ba7ab860bb4ea72c94");
      array1.push("0x8a3552d60a98e0ade765adddad0a2e420ca9b1eef5f326ba7ab860bb4ea72c93");  //unmuch!
      array1.push("0x28ee50ccca7572e60f382e915d3cc323c3cb713b263673ba830ab179d0e5d57f");

      await expect(
        hardhatToken.connect(addr1).premint(1,array1,{ value: ethers.utils.parseEther("0.5") })
        ).to.be.revertedWith("You don't have a whitelist!");
    }
    );
  });

  describe("WhiteList NG > unmuch addr",function(){
    it("Shoud NG",async function(){
      await hardhatToken.setOnlyWhitelisted(false);
      await hardhatToken.setPresaleRoots("0x5c0965c65dfb1547d128efb3e61004f43995418da2d36870318fd1d53a6ec3ab");

      var array1 = new Array();
      array1.push("0x8a3552d60a98e0ade765adddad0a2e420ca9b1eef5f326ba7ab860bb4ea72c94");
      array1.push("0x28ee50ccca7572e60f382e915d3cc323c3cb713b263673ba830ab179d0e5d57f");

      await expect(
        hardhatToken.connect(addr5).premint(1,array1,{ value: ethers.utils.parseEther("0.5") })
        ).to.be.revertedWith("You don't have a whitelist!");
    }
    );
  });
});