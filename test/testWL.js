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

//   describe("mint_onlywl & mint paused",function(){
//     it("Shoud paused",async function(){
//       var array1 = new Array();
//       await expect(
//         hardhatToken.mint_onlywl(1, array1)
//         ).to.be.revertedWith("mint is paused");

//       await expect(
//         hardhatToken.mint(1)
//         ).to.be.revertedWith("mint is paused");
//     }
//     );
//   });

  // MarkleTree in addr1,addr2,addr3,addr4
  // ref> https://play-nft.art/merkle_tree
  describe("WhiteList OK",function(){
    it("Shoud OK lead",async function(){
      await hardhatToken.setPhase(1);
      await hardhatToken.setMerkleRoot("0x0f039e2dcb7e5c5f4b666316dc0174350b70607386193ae24f3550ad17de4c9e");

      var array1 = new Array();
      array1.push("0x569ab48c70cc15322c9253243aab005d1c64df7c33031cf8dfb5a8ac071d368d");
      array1.push("0x54a05d6d1f130a865bccb167e39e3cc3302f6b209e80fbfbe4fde30a674370f8");
      array1.push("0x0c7573e01170c5a03b7a10e33d287e3b9118647de33c7b6eb82680e52c0a4e69");

      const addr1Balance = await hardhatToken.balanceOf(addr1.address);
      expect(addr1Balance).to.equal(0);

      await hardhatToken.connect(addr1).mint_onlywl(1,11,array1,{ value: ethers.utils.parseEther("0.5") });

      const addr1Balance_mint = await hardhatToken.balanceOf(addr1.address);
      expect(addr1Balance_mint).to.equal(1);
    }
    );
    it("Shoud OK last",async function(){
      await hardhatToken.setPhase(1);
      await hardhatToken.setMerkleRoot("0x0f039e2dcb7e5c5f4b666316dc0174350b70607386193ae24f3550ad17de4c9e");

      // const root = hardhatToken.getMerkleRoot();
      // expect(root).to.equal(0x4661713d0f432967b9e36aa9dce8d8ab1365c564fe39baa2040cd9e00c1506ee);
      var array1 = new Array();
      array1.push("0xa2564ac53b2aa317a2ba169b156d8babc16e8ddad7c3e15228c533303e1adee7");
      array1.push("0x397bd2207b0cd38535a2cd2f2b8abb7fe967fb142e5fa26e35b19a76cdd1d62c");

      const addr1Balance = await hardhatToken.balanceOf(addr5.address);
      expect(addr1Balance).to.equal(0);

      await hardhatToken.connect(addr5).mint_onlywl(1,15,array1,{ value: ethers.utils.parseEther("0.5") });

      const addr1Balance_mint = await hardhatToken.balanceOf(addr5.address);
      expect(addr1Balance_mint).to.equal(1);
    }
    );
  });

  describe("WhiteList NG > unmuch _merkleProof",function(){
    it("Shoud NG root",async function(){
      await hardhatToken.setPhase(1);
      await hardhatToken.setMerkleRoot("0x0f039e2dcb7e5c5f4b666316dc0174350b70607386193ae24f3550ad17de4c9f"); //unmuch

      var array1 = new Array();
      array1.push("0x569ab48c70cc15322c9253243aab005d1c64df7c33031cf8dfb5a8ac071d368d");
      array1.push("0x54a05d6d1f130a865bccb167e39e3cc3302f6b209e80fbfbe4fde30a674370f8");
      array1.push("0x0c7573e01170c5a03b7a10e33d287e3b9118647de33c7b6eb82680e52c0a4e69");

      await expect(
        hardhatToken.connect(addr1).mint_onlywl(1,11,array1,{ value: ethers.utils.parseEther("0.5") })
        ).to.be.revertedWith("You don't have a whitelist!");
    }
    );
    it("Shoud NG proof",async function(){
      await hardhatToken.setPhase(1);
      await hardhatToken.setMerkleRoot("0x0f039e2dcb7e5c5f4b666316dc0174350b70607386193ae24f3550ad17de4c9e");

      var array1 = new Array();
      array1.push("0x569ab48c70cc15322c9253243aab005d1c64df7c33031cf8dfb5a8ac071d368d");
      array1.push("0x54a05d6d1f130a865bccb167e39e3cc3302f6b209e80fbfbe4fde30a674370f9");  //unmuch
      array1.push("0x0c7573e01170c5a03b7a10e33d287e3b9118647de33c7b6eb82680e52c0a4e69");

      await expect(
        hardhatToken.connect(addr1).mint_onlywl(1,11,array1,{ value: ethers.utils.parseEther("0.5") })
        ).to.be.revertedWith("You don't have a whitelist!");
    }
    );
    it("Shoud NG amount",async function(){
      await hardhatToken.setPhase(1);
      await hardhatToken.setMerkleRoot("0x0f039e2dcb7e5c5f4b666316dc0174350b70607386193ae24f3550ad17de4c9e");

      var array1 = new Array();
      array1.push("0x569ab48c70cc15322c9253243aab005d1c64df7c33031cf8dfb5a8ac071d368d");
      array1.push("0x54a05d6d1f130a865bccb167e39e3cc3302f6b209e80fbfbe4fde30a674370f8");
      array1.push("0x0c7573e01170c5a03b7a10e33d287e3b9118647de33c7b6eb82680e52c0a4e69");

      await expect(
        hardhatToken.connect(addr1).mint_onlywl(1,12,array1,{ value: ethers.utils.parseEther("0.5") })  //amount unmuch
        ).to.be.revertedWith("You don't have a whitelist!");
    }
    );
  });

  describe("getWLRemain",function(){
    it("Shoud OK",async function(){
      await hardhatToken.setPhase(1);
      await hardhatToken.setMerkleRoot("0x0f039e2dcb7e5c5f4b666316dc0174350b70607386193ae24f3550ad17de4c9e");

      var array1 = new Array();
      array1.push("0x569ab48c70cc15322c9253243aab005d1c64df7c33031cf8dfb5a8ac071d368d");
      array1.push("0x54a05d6d1f130a865bccb167e39e3cc3302f6b209e80fbfbe4fde30a674370f8");
      array1.push("0x0c7573e01170c5a03b7a10e33d287e3b9118647de33c7b6eb82680e52c0a4e69");

      const addr1Balance = await hardhatToken.balanceOf(addr1.address);
      expect(addr1Balance).to.equal(0);

      await hardhatToken.connect(addr1).mint_onlywl(6,11,array1,{ value: ethers.utils.parseEther("0.5") });

      const addr1Remain_mint = await hardhatToken.getWLRemain(addr1.address,11,array1);
      expect(addr1Remain_mint).to.equal(5);
    }
    );

    it("Shoud NG",async function(){
      await hardhatToken.setPhase(1);
      await hardhatToken.setMerkleRoot("0x0f039e2dcb7e5c5f4b666316dc0174350b70607386193ae24f3550ad17de4c9e");

      var array1 = new Array();
      array1.push("0x569ab48c70cc15322c9253243aab005d1c64df7c33031cf8dfb5a8ac071d368d");
      array1.push("0x54a05d6d1f130a865bccb167e39e3cc3302f6b209e80fbfbe4fde30a674370f8");
      array1.push("0x0c7573e01170c5a03b7a10e33d287e3b9118647de33c7b6eb82680e52c0a4e69");

      const addr1Balance = await hardhatToken.balanceOf(addr1.address);
      expect(addr1Balance).to.equal(0);

      await hardhatToken.connect(addr1).mint_onlywl(11,11,array1,{ value: ethers.utils.parseEther("0.5") });

      const addr1Remain_mint = await hardhatToken.getWLRemain(addr1.address,11,array1);
      expect(addr1Remain_mint).to.equal(0);

      await expect(
        hardhatToken.connect(addr1).mint_onlywl(1,11,array1,{ value: ethers.utils.parseEther("0.5") })  //amount unmuch
        ).to.be.revertedWith("claim is over max amount");


    }
    );
  });

//   describe("mint_onlywl require",function(){
//     it("Shoud require",async function(){
//       await hardhatToken.pause(false);
//       await hardhatToken.setPresaleRoots("0x5c0965c65dfb1547d128efb3e61004f43995418da2d36870318fd1d53a6ec3ab");

//       var array1 = new Array();
//       array1.push("0x8a3552d60a98e0ade765adddad0a2e420ca9b1eef5f326ba7ab860bb4ea72c94");
//       array1.push("0x28ee50ccca7572e60f382e915d3cc323c3cb713b263673ba830ab179d0e5d57f");
//       var array2 = new Array();
//       array2.push("0x00314e565e0574cb412563df634608d76f5c59d9f817e85966100ec1d48005c0");
//       array2.push("0x28ee50ccca7572e60f382e915d3cc323c3cb713b263673ba830ab179d0e5d57f");
//       var array3 = new Array();
//       array3.push("0xf4ca8532861558e29f9858a3804245bb30f0303cc71e4192e41546237b6ce58b");
//       array3.push("0x343750465941b29921f50a28e0e43050e5e1c2611a3ea8d7fe1001090d5e1436");
//       //require
//       await expect(
//         hardhatToken.connect(addr1).mint_onlywl(0, array1)
//         ).to.be.revertedWith("need to mint at least 1 NFT");
      
//       await expect(
//         hardhatToken.connect(addr1).mint_onlywl(11, array1)
//         ).to.be.revertedWith("claim is over max amount at once");
        
//       for(let i=0;i<2;i++){   //max mint
//         await  hardhatToken.connect(addr1).mint_onlywl(5, array1,{ value: ethers.utils.parseEther("0.5") });
//       }
//       for(let i=0;i<2;i++){   //max mint
//         await  hardhatToken.connect(addr2).mint_onlywl(5, array2,{ value: ethers.utils.parseEther("0.5") });
//       }
//       await expect(
//           hardhatToken.connect(addr3).mint_onlywl(1, array3,{ value: ethers.utils.parseEther("0.5") })
//           ).to.be.revertedWith("claim is over the max supply");
//     }
//     );
//   })

//   describe("public function",function(){
//     it("getMaxMintAmount WL",async function(){
//       await hardhatToken.pause(false);
      
//       const amount = await  hardhatToken.connect(addr1).getMaxMintAmount();
//       expect(amount).to.equal(10);
//     }
//     );

//     it("getMaxMintAmount public",async function(){
//       await hardhatToken.pause(false);
//       await hardhatToken.setOnlyWhitelisted(false);
      
//       const amount = await  hardhatToken.connect(addr1).getMaxMintAmount();
//       expect(amount).to.equal(5);
//     }
//     );

//     it("getRemainMintAmountWL 0",async function(){
//       await hardhatToken.pause(false);
//       await hardhatToken.setPresaleRoots("0x5c0965c65dfb1547d128efb3e61004f43995418da2d36870318fd1d53a6ec3ab");

//       var array1 = new Array();
//       array1.push("0x8a3552d60a98e0ade765adddad0a2e420ca9b1eef5f326ba7ab860bb4ea72c94");
//       array1.push("0x28ee50ccca7572e60f382e915d3cc323c3cb713b263673ba830ab179d0e5d57f");

//       const amount = await  hardhatToken.connect(addr1).getRemainMintAmountWL(addr1.address,array1);
//       expect(amount).to.equal(10);
//     }
//     );

//     it("getRemainMintAmountWL 1",async function(){
//       await hardhatToken.pause(false);
//       await hardhatToken.setPresaleRoots("0x5c0965c65dfb1547d128efb3e61004f43995418da2d36870318fd1d53a6ec3ab");

//       var array1 = new Array();
//       array1.push("0x8a3552d60a98e0ade765adddad0a2e420ca9b1eef5f326ba7ab860bb4ea72c94");
//       array1.push("0x28ee50ccca7572e60f382e915d3cc323c3cb713b263673ba830ab179d0e5d57f");

//       await  hardhatToken.connect(addr1).mint_onlywl(1, array1,{ value: ethers.utils.parseEther("0.5") });
//       const amount = await  hardhatToken.connect(addr1).getRemainMintAmountWL(addr1.address,array1);
//       expect(amount).to.equal(9);
//     }
//     );

//     it("getRemainMintAmount 0",async function(){
//       await hardhatToken.pause(false);
//       await hardhatToken.setOnlyWhitelisted(false);

//       const amount = await  hardhatToken.connect(addr1).getRemainMintAmount(addr1.address);
//       expect(amount).to.equal(5);
//     }
//     );

//     it("getRemainMintAmount 1",async function(){
//       await hardhatToken.pause(false);
//       await hardhatToken.setOnlyWhitelisted(false);

//       await  hardhatToken.connect(addr1).mint(1,{ value: ethers.utils.parseEther("0.5") });
//       const amount = await  hardhatToken.connect(addr1).getRemainMintAmount(addr1.address);
//       expect(amount).to.equal(4);
//     }
//     );
//   });

//   it("getWhitelistExit OK",async function(){
//     await hardhatToken.pause(false);
//     await hardhatToken.setPresaleRoots("0x5c0965c65dfb1547d128efb3e61004f43995418da2d36870318fd1d53a6ec3ab");

//     var array1 = new Array();
//     array1.push("0x8a3552d60a98e0ade765adddad0a2e420ca9b1eef5f326ba7ab860bb4ea72c94");
//     array1.push("0x28ee50ccca7572e60f382e915d3cc323c3cb713b263673ba830ab179d0e5d57f");

//     const _exit = await  hardhatToken.connect(addr1).getWhitelistExit(addr1.address,array1);
//     expect(_exit).to.equal(true);
//   }
//   );

//   it("getWhitelistExit NG",async function(){
//     await hardhatToken.pause(false);
//     await hardhatToken.setPresaleRoots("0x5c0965c65dfb1547d128efb3e61004f43995418da2d36870318fd1d53a6ec3ab");

//     var array1 = new Array();
//     //array1.push("0x8a3552d60a98e0ade765adddad0a2e420ca9b1eef5f326ba7ab860bb4ea72c94");
//     array1.push("0x8a3552d60a98e0ade765adddad0a2e420ca9b1eef5f326ba7ab860bb4ea72c93");  // unmuch!
//     array1.push("0x28ee50ccca7572e60f382e915d3cc323c3cb713b263673ba830ab179d0e5d57f");

//     const _exit = await  hardhatToken.connect(addr1).getWhitelistExit(addr1.address,array1);
//     expect(_exit).to.equal(false);
//   }
//   );

});