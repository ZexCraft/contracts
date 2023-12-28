# ZexCraft

### Short Description

Breed your NFTs with other NFTs and form AI generated variants aka. ZexCrafts, building your legacy by growing your family tree.

### Long Description

#### Overview
ZexCraft is a NFT minting/breeding platform where users can form relationships between NFTs and grow their legacy and visualize it in a family tree. Users can unleash their creativity by creating NFTs with an AI prompt. NFT owners can form relationships using their NFTs with other NFTs owned by other users. By forming relationships users can create hybrid family trees like BAYC/PUNK, Azuki/PCT etc. NFTs when they breed with each other form new NFTs that look like a combination of both NFT using AI. Every AI generated NFT has rarity that determines its value. There are 6 levels of rarity: Common, Basic, Rare, Epic, Legendary, ZexStar. Rarity is generated on-chain and this rarity determines the colour theme of the NFT. Users can purchase power-ups to boost their NFTs and their breeding abilities. From the user perspective, these ZexCrafted NFTs create new communities and new possibilities to form CrossNFTCollection relationships across different blockchains. NFT collections in any blockchain will be able to form relationships, create new offsprings and grow their family line.

#### User story
User enters the app and can view other AI generated NFTs and imported NFTs from different blockchains in the home page. User can also view relationships and family trees.

If the user does not own any NFT, he can choose to create a new one with an AI prompt. He goes to the create page, chooses the chain in which he needs to pay the mint fee to generate the NFT. The user pays with Craft Tokens (CFT) as the mint fee on PEGO Mainnet. In future, cross-chain NFT minting will be supported. On paying the mint fee, the user provides a prompt that triggers the smart contract to generate a new NFT. The smart contract produces rarity and creates the new NFT on-chain. After successfully creating a new NFT, the user makes an another call to create an NFT-owned account for the new ZexCrafted NFT.

If the user already owns an NFT, the user can go to his profile and import his NFT by entering the contract address and token id. The user can import any NFT on the supported blockchains. This transaction creates an NFT-owned account for his NFT in this application.

After creating the NFT owned account for the NFT, the user can choose to form relationships with any NFT that is created/imported/bred in ZexCraft. The user needs the signature of the other NFT holder to form the relationship. By forming the relationship, the pair gets added to an existing family tree if compatible (BAYC/PUNK family tree only accepts a BAYC or PUNK partner) or can choose to create a new family tree. The user will be able to view the interactive family tree in the application.

The pair can opt to breed and create a new NFT. This generates a new NFT using AI which will be the blend of both the parent NFTs. This NFT has its own rarity which is generated in the smart contract. After successfully creating a new NFT, the pair makes an another call to create an NFT-owned account for the new ZexCrafted NFT.

The user can go to Power-ups section to purchase power-ups using any supported currency. Using these power-ups, users can breed better ZexCraftNFTs.

### Technical Description

1. Users when they create a new NFT deploy an Proxy ERC6551 Account in the same transaction. This will act as the smart account of the NFT. 
2. Craft Tokens are VRC25 tokens which will act as the incentivization layer for the application.
3. Users when they form a relationship, deploy a Proxy relationship contract which will own the children bred out of it.

### Viction Mainnet Deployments

**ERC6551 Account Implementation** => 0x16CBC6Cb38D19B73A3b545109c70b2031d20EA37

**ERC6551 Account Registry** => 0xd37ca03a13bD2725306Fec4071855EE556037e2e

**Relationship Implementation** => 0x4ab8f50796b059aE5C8b8534afC6bb4c84912ff6

**Relationship Registry** => 0x7125e097a72cCf547ED6e9e98bCc09BE3AC61997

**ZexCraft (Main Contract)** => 0x50751BD8d7b0a84c422DE96A56426a370F31a42D

**CraftToken (VRC25)** => 0x08AC2b69feB202b34aD7c65E5Ac876E901CA6216


### Viction Testnet Deployments

**ERC6551 Account Implementation** => 0x7125e097a72cCf547ED6e9e98bCc09BE3AC61997

**ERC6551 Account Registry** => 0x50751BD8d7b0a84c422DE96A56426a370F31a42D

**Relationship Implementation** => 0x08AC2b69feB202b34aD7c65E5Ac876E901CA6216

**Relationship Registry** => 0x108A91edD1329e17409A86b54D4204A102534ec3

**ZexCraft (Main Contract)** => 0xc6b011774FE1393AE254d19456e76F0f1b5B09Eb

**CraftToken (VRC25)** => 0xC044FCe37927A0Cb55C7e57425Fe3772181228a6


### Important Links

**Frontend** => https://github.com/ZexCraft/frontend

**Backend** => https://github.com/ZexCraft/backend

**Contracts** => https://github.com/ZexCraft/contracts

**Pitch Deck** => https://www.canva.com/design/DAF4FCASRJQ/uTjvpJGtGXq4ZT8wNSp4Bw/view?utm_content=DAF4FCASRJQ&utm_campaign=designshare&utm_medium=link&utm_source=editor

**Demo Video** => https://www.canva.com/design/DAF4Mg8UsgA/ZJwRXMWb33Pacbrzm8klQA/watch?utm_content=DAF4Mg8UsgA&utm_campaign=designshare&utm_medium=link&utm_source=editor

**Website** => https://viction.zexcraft.xyz


### Screenshots


<img width="1440" alt="Screenshot 2023-12-28 at 5 46 45 AM" src="https://github.com/ZexCraft/frontend/assets/79229998/c28976f5-f0a5-4208-9748-d11d6d487c4c">
<img width="1440" alt="Screenshot 2023-12-28 at 5 46 37 AM" src="https://github.com/ZexCraft/frontend/assets/79229998/01a20414-561d-492a-a6a3-c2eec34299e5">
<img width="1440" alt="Screenshot 2023-12-28 at 5 46 27 AM" src="https://github.com/ZexCraft/frontend/assets/79229998/8a984cb9-2269-44ca-b227-1d300633d2c2">
<img width="1440" alt="Screenshot 2023-12-28 at 5 46 04 AM" src="https://github.com/ZexCraft/frontend/assets/79229998/db5b714a-9585-47cc-a604-135881e267ad">
<img width="1440" alt="Screenshot 2023-12-28 at 5 45 48 AM" src="https://github.com/ZexCraft/frontend/assets/79229998/dcd850d6-f045-4df9-b72c-e116fbecf1dd">
<img width="1440" alt="Screenshot 2023-12-28 at 5 45 29 AM" src="https://github.com/ZexCraft/frontend/assets/79229998/22288875-eaea-4396-97a4-5cdbda19d67e">
<img width="1440" alt="Screenshot 2023-12-28 at 5 45 19 AM" src="https://github.com/ZexCraft/frontend/assets/79229998/e7f84b8b-3327-49cb-b6de-df22e435dec6">
<img width="1440" alt="Screenshot 2023-12-28 at 5 45 12 AM" src="https://github.com/ZexCraft/frontend/assets/79229998/1bfb0453-8497-4966-9d30-40c62a3978b0">
<img width="1440" alt="Screenshot 2023-12-28 at 5 43 57 AM" src="https://github.com/ZexCraft/frontend/assets/79229998/9531b60f-3b81-42e9-88d7-94e10da12d82">
<img width="1440" alt="Screenshot 2023-12-28 at 5 43 31 AM" src="https://github.com/ZexCraft/frontend/assets/79229998/10bb0428-3ea7-41eb-8b74-2f4f4f3fa790">
<img width="1440" alt="Screenshot 2023-12-28 at 5 43 16 AM" src="https://github.com/ZexCraft/frontend/assets/79229998/c8fcc5dd-dfb6-4bc0-888d-ec0735be7daf">




