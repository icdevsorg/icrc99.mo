import ICRC16 "mo:candy/types";
import Principal "mo:base/Principal";
import ICRC7Service "mo:icrc7-mo/service";

// icrc99_public type_definitions.mo

import Prim "mo:prim";

module {

public type ICRC16Map = [(Text, ICRC16.CandyShared)];

// The Network public type extending to support cross-chain functionalities
public type Network = {
  #Ethereum: ?Nat; //chain id 
    #Solana: ?Nat; //chain id
    #Bitcoin: ?Text;
    #IC: ?Text; //identifier
    #Other: ICRC16Map; 
};

// Remote contract details to point to a specific blockchain contract
public type RemoteNFTPointer =  {
    network: Network;
    contract: Text;
    tokenId: Nat;
  };

public type Account = ICRC7Service.Account;

// Structure to request remote ownership status for a specific NFT
public type RequestRemoteOwnerRequest = {
  remoteNFTPointer: RemoteNFTPointer;
  memo: ?Blob;
  createdAtTime: ?Nat;
};

// Structure for requesting the cost of casting an NFT to a remote network
public type CastCostRequest =  RemoteNFTPointer;

// Cost associated with a casting operation to a remote blockchain
public type RemoteTokenCost = {
  symbol: Text;
  amount: Nat;
  decimals: Nat;
  network: Network;
  contractId: Text;
};

public type RemoteOwnerResult = {
  #Ok : RemoteOwner;
  #Err : RemoteOwnershipUpdateError;
};

public type RemoteContractPointer = {
  network: Network;
  contract: Text;
};

// Representation of the NFT ownership status (local or remote)
public type RemoteOwner = {
  #local : ICRC7Service.Account;
  #remote : {
    contract: RemoteContractPointer;
    owner: Text;
    timestamp: Nat;
  };
};

// Request structure for casting an NFT to a remote network
public type CastRequest = {
  tokenId: Nat;
  fromSubaccount: ?Blob;
  remoteContract: RemoteContractPointer;
  targetOwner: Text;
  memo: ?Blob;
  created_at_time: ?Nat;
  gasPrice: ?Nat;
  gasLimit: ?Nat;
};

public type OrchestratorCastRequest = {
  castId: Nat;
  tokenId: Nat;
  originalCaller: Account;
  originalMinterAccount: ?Account;
  nativeContract: RemoteContractPointer;
  remoteContract: RemoteContractPointer;
  targetOwner: Text;
  memo: ?Blob;
  created_at_time: ?Nat;
  gasPrice: ?Nat;
  gasLimit: ?Nat;
};

// Structure for updating the remote ownership status of an NFT
public type RemoteOwnershipUpdateRequest = {
  tokenId: Nat;
  remoteContract: RemoteContractPointer;
  memo: ?Blob;
};

// Result of a remote ownership update request
public type RemoteOwnershipUpdateResult = {
  #Ok : RemoteOwner;
  #Err : RemoteOwnershipUpdateError;
};

// Possible errors while attempting to update remote ownership
public type RemoteOwnershipUpdateError = {
  #QueryError : Text;
  #GenericError : Text;
  #NotFound;
  #Unauthorized;
  #FoundLocally : ICRC7Service.Account;
  #InsufficientAllowance : (Nat, Nat);
  #InsufficientBalance : (Nat, Nat);
  #InsufficientCycles : (Nat, Nat);
};

public type CastStateShared = {
  castId: Nat;
  originalRequest: OrchestratorCastRequest;
  startTime: Nat;
  status: CastStatus;
  history: [(CastStatus, Nat)]; //status, timestamp
};

// Representation of casting status
public type MintStatus = {
  #VerifyingOwnership;
  #RetrievingCollectionMetadata;
  #RetrievingNFTMetadata;
  #WritingContract: {
    trxId:  ?Text;
    nextQuery: Nat;
    retries: Nat;
  };
  #MintingNFT: {
    trxId: ?Text;
    nextQuery: Nat;
    retries: Nat;
  };
  #TransferringNFT: {
    trxId: ?Text;
    nextQuery: Nat;
    retries: Nat;
  };
  #Complete: {
    contractTrx: ?Text;
    mintTrx:  ?Text;
    transferTrx:  ?Nat;
  };
  #Error: MintError
};

// Errors that could occur during casting status updates
public type MintError = {
    #Unauthorized;
    #CollectionError: Text;
    #NFTError: Text;
    #InvalidTransaction: Text;
    #ContractNotVerified: {
      #TooManyRetries: Nat;
      #NoConsensus;
    };
    #MintNotVerified: {
      #TooManyRetries: Nat;
      #NoConsensus;
    };
    #TransferNotVerified:  {
      #TooManyRetries: Nat;
      #NoConsensus;
    };
    #MintError: Text;
    #ApprovalError: Text;
    #GenericError: Text;
  };

   // Structure for casting operation results
public type CastResult = {
  #Ok : Nat;
  #Err : CastError;
};

public type CastStatus = {
    #Created; //timestamp
    #SubmittingToOrchestrator: Nat; //timestamp
    #SubmittedToOrchestrator : {
      remoteCastId: Nat; //Transaction ID on 
      localCastId: Nat;
    };
    #WaitingOnContract: { //reported to us by the orchestrator
      transaction: Text;
    };
    #WaitingOnMint: { //reported to us by the orchestrator
      transaction: Text;
    };  
    #WaitingOnTransfer: { //reported to us by the orchestrator
      transaction: Text;
    };
    #RemoteFinalized: Text; //block/hash of the included block
    #Completed: Nat; //block of local transfer to canister
    #Error: CastError;
  };

// Representation of errors during the casting process
public type CastError = {
  #Unauthorized;
  #NoCkNFTCanister;
  #InvalidContract;
  #ExistingCast : Nat;
  #NetworkError : Text;
  #NotFound;
  #ContractNotVerified : {
    #TooManyRetries: Nat;
    #NoConsensus: Null;
  };
  #MintNotVerified : {
    #TooManyRetries: Nat;
    #NoConsensus: Null;
  };
  #TransferNotVerified : {
    #TooManyRetries: Nat;
    #NoConsensus;
  };
  #InvalidTransaction : Text;
  #InsufficientAllowance : (Nat, Nat);
  #InsufficientBalance : (Nat, Nat);
  #InsufficientCycles : (Nat, Nat);
  #GenericError : Text;
};


// The main service public type for the ICRC-99 standard
public type ICRC99Service = {
  icrc99_native_chain: query() ->  async RemoteContractPointer ;
  icrc99_remote_owner_of: ([Nat]) -> async [?RemoteOwner];
  icrc99_request_remote_owner_status: ([RequestRemoteOwnerRequest], ?ICRC7Service.Account) -> async [?RemoteOwnerResult];
  icrc99_cast: ([CastRequest], ?ICRC7Service.Account) -> async [?CastResult];
  icrc99_cast_cost: ([CastCostRequest]) -> async RemoteTokenCost;
  icrc99_cast_status: ([Nat], account : ?Account) -> async [?(CastStateShared)];
};

}