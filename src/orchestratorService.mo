import ICRC16 "mo:candy/types";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import EVM_RPC "EVMRPCService";

module {

  public type ICRC16Map = [(Text, ICRC16.CandyShared)];

  public type GetCallResult = {
    #Ok: Text;
    #Err: RemoteError;
  };

  public type RemoteError = {
    #NotImplemented;
    #GenericError: Text;
    #Unauthorized;
    #RPC: {
      #Ethereum : EVM_RPC.RpcError;
    };
    #NetworkRCPNotFound;
    #InsufficientAllowance : (Nat, Nat);
    #InsufficientBalance : (Nat, Nat);
    #InsufficientCycles: (Nat, Nat);
  };

  public type Network = { 
    #Ethereum: ?Nat; //chain id 
    #Solana: ?Nat; //chain id
    #Bitcoin: ?Text;
    #IC: ?Text; //identifier
    #Other: ICRC16Map; 
  };

  public type RemoteNFTPointer =  {
    network: Network;
    contract: Text;
    tokenId: Nat;
  };

  public type SolonaRPCService = {
    #Generic: EVM_RPC.RpcApi;
  };

  public type BitcoinRPCService = {
    #Generic: EVM_RPC.RpcApi;
  };

  public type ICRPCService = {
    #Generic: EVM_RPC.RpcApi;
  };

  public type FusionRPCService = {
    #Ethereum: {
      rpc: EVM_RPC.RpcService;
      canisterId: Principal;
    };
    #Solana: {
      rpc: SolonaRPCService;
      canisterId: Principal;
    };
    #Bitcoin: {
      rpc: BitcoinRPCService;
      canisterId: Principal;
    };
    #IC: {
      rpc: ICRPCService;
      canisterId: Principal;
    };
    #Other: [(Text, ICRC16.CandyShared)];
  };

  public type OrchestratorConfig = {
    
    #MapNetwork: {
      network : Network;
      service: FusionRPCService;
      action : {
        #Add;
        #Remove;
      }
    };


  };

  public type OrchestratorConfigResult = {
    #Ok: Nat;
    #Err: OrchestratorConfigError;
  };

  public type OrchestratorConfigError = {
    #GenericError: Text;
    #Unauthorized;
    #MapNetwork: {
      #NotFound;
      #Exists;
    };
  };

  public type Account = {
    owner: Principal;
    subaccount: ?Blob;
  };

  public type RemoteContractPointer = {
    network: Network;
    contract: Text;
  };  

  public type CastRequest = {
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

  // Structure for casting operation results
public type CastResult = {
  #Ok : Nat;
  #Err : CastError;
};

// Representation of errors during the casting process
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


  public type Service = actor {
    get_remote_owner : ([RemoteNFTPointer]) -> async [?GetCallResult];
    get_remote_meta : ([RemoteNFTPointer]) -> async [?GetCallResult];
    cast : (CastRequest) -> async CastResult;
  };

};