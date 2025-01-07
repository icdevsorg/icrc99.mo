import ICRC16 "mo:candy/types";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import EVM_RPC "EVMRPCService";

module {

  public type ICRC16Map = [(Text, ICRC16.CandyShared)];

  public type RpcServices = EVM_RPC.RpcServices;

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
      #EthereumMultiSend: EVM_RPC.MultiSendRawTransactionResult;
    };
    #NetworkRCPNotFound;
    #NoCkNFTCanister;
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

  public type ContractPointer = {
    network: Network;
    contract: Text;
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
    #SetTecdsaKeyName: Text;


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

  public type ApprovalAddressRequest = {
    account: Account;
    remoteNFTPointer: RemoteNFTPointer;
  };


  public type MintRequestId = Nat;

  public type MintResult = {
    #Ok: MintRequestId;
    #Err: MintError;
  };

  public type MintError = RemoteError or {
    #InvalidRemoteNFTPointer;
    #InvalidAccount;
    #InvalidSpender;
    #InvalidResumeOption;
    #InvalidMintRequestId;
    #InvalidMintStatus;
    #InvalidMintRequest;
    #NoCkNFTCanister;
  };

  public type MintStatus = {
    #Transferring;
    #CheckingOwner: {
      retries: Nat;
      nextQuery: Nat;
    };
    #RetrievingMetadata: {
      retries: Nat;
      nextQuery: Nat;
    };
    #Minting;
    #Complete: {
      mintTrx: Nat;
      approvalTrx: ?Nat;
      approvalError: ?Text;
    };
    #Err : {
      #InvalidTransfer : Text; //Error from RPC
      #OwnershipNotVerified : {
        #InvalidOwner;
        #TooManyRetries: Nat;
        #RemoteError: RemoteError;
      };
      #InvalidMetadata: Text;
      #MetadataError: Text;
      #MintError: Text;
      #ApprovalError: Text;
      #GenericError: Text;
    };
    
  };

  public type MintResumeOption = {
    #StartOwnershipVerification;
    #StartMetadataTransfer;
    #StartMint;
  };

  public type MintRequest = {
    nft: RemoteNFTPointer;
    mintToAccount: Account;
    spender: ?Account;
    resume: ?(Nat, MintResumeOption)
  };

  public type  CreateCanisterResponse = {
    #Ok: Principal;
    #Err: CreateCanisterError;
  };

    public type  CreateRemoteResponse = {
    #Ok: Nat;
    #Err: CreateRemoteError;
  };

  public type CreateCanisterError = RemoteError;
  public type CreateRemoteError = RemoteError;

  public type CanisterDefaults =  {
   symbol: ?Text;
   name: ?Text;
   description: ?Text;
   logo: ?Text;
   
  };
  public type CastRequest = {
    castId: Nat;
    tokenId: Nat;
    uri: Text;
    originalCaller: Account;
    originalMinterAccount: ?Account;
    nativeContract: ContractPointer;
    remoteContract: ContractPointer;
    targetOwner: Text;
    memo: ?Blob;
    created_at_time: ?Nat;
    gasPrice: ?Nat;
    gasLimit: ?Nat;
    maxPriorityFeePerGas: ?Nat;
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

  public type ContractStateShared = {
    contractId : Nat;
     ckNFTCanisterId : ?Nat;
     writingContractCanisterId: ?Text;
     nextQuery: ?Nat;
     retries: ?Nat;
     address: ?Text;
     network: ?Network;
     confirmed: Bool;
     deploymentTrx: ?Text;
     contractType : {
      #Owned: ContractPointer;
      #Remote;
    };
  };


  public type Service = actor {
    get_remote_owner : ([RemoteNFTPointer]) -> async [?GetCallResult];
    get_remote_meta : ([RemoteNFTPointer]) -> async [?GetCallResult];
    get_remote_approval_address:  (ApprovalAddressRequest, ?Account) -> async ?Text; //not a query because it may require a call to the tecdsa chain
    
    get_ck_nft_canister: query ([ContractPointer]) -> async [?Principal];
    get_creation_cost: (ContractPointer) -> async Nat;
    get_mint_cost: ([MintRequest]) -> async [?Nat];
    get_remote_cost: (ContractPointer, Network) -> async Nat;
    create_canister: (ContractPointer, CanisterDefaults, Account) -> async CreateCanisterResponse;
    mint: (mintRequest: MintRequest,  account: ?Account) -> async MintResult;
    create_remote : (ContractPointer, Network, Nat, Nat, account: ?Account) -> async CreateRemoteResponse;
    get_icrc99_address: (Principal, Network) -> async ?(Text,[Nat8]);
    get_mint_status: ([Nat]) -> async [?MintStatus];
    get_remote_status: ([Nat]) -> async [?ContractStateShared];
    get_remote: ([(ContractPointer, Network)]) -> async [?ContractStateShared];
    calc_eth_call_cycles: shared query (EVM_RPC.RpcServices, Nat, Text) -> async Nat;
    cast : (CastRequest) -> async CastResult;
  };

};