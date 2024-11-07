// please do not import any types from your project outside migrations folder here
// it can lead to bugs when you change those types later, because migration types should not be changed
// you should also avoid importing these types anywhere in your project directly from here
// use MigrationTypes.Current property instead
import ICRC16 "mo:candy/types";
import VectorLib "mo:vector";
import MapLib "mo:map/Map";
import SetLib "mo:map/Set";
import Array "mo:base/Array";
import Principal "mo:base/Principal";
import BTreeLib "mo:stableheapbtreemap/BTree";
import ICRC7 "../../../../../../PanIndustrial/code/icrc7.mo/src";

import Service "../../service";

//import EVM_RPC "../../EVMRPCService";


module {

  public let Map = MapLib;
  public let Set = SetLib;
  public let BTree = BTreeLib;
  public let Vector = VectorLib;

  public type RemoteContractPointer =  Service.RemoteContractPointer;
  public type RemoteOwner =            Service.RemoteOwner;

  //public type FusionRPCService =      Service.FusionRPCService;
  public type Network =               Service.Network;
  public type CastRequest =           Service.CastRequest;

  public type Account =             Service.Account;

  public type CastState = {
    castId: Nat;
    var remoteCastId: ?Nat;
    originalRequest: CastRequest;
    nativeChain: RemoteContractPointer;
    originalMinter: Account;
    originalCaller: Principal;
    var includedCycles : Nat;
    var usedCycles : Nat;
    startTime: Nat;
    var status: CastStatus;
    history: Vector.Vector<(CastStatus, Nat)>; //status, timestamp
  };

  /// A map that matches A Network with a set of Fusion RPC Services.

  //public type FusionRPCMap = Map.Map<Service.Network, Set.Set<FusionRPCService>>;

  //See https://m7sm4-2iaaa-aaaab-qabra-cai.raw.ic0.app/?tag=888958561
  public func NetworkEq(n1: Service.Network, n2: Service.Network): Bool {
    n1 == n2;
  };

  public func NetworkHash32 (n: Service.Network): Nat32 {
    var accumulator = 0 : Nat32;
    switch (n) {
      case (#Ethereum(?n)){
        accumulator +%= 2445342;
        accumulator +%= Map.nhash.0(n);
      };
      case(#Ethereum(_)){
        accumulator +%= 2445342;
      };
      case (#Solana(?n)){
        accumulator +%= 643454;
        accumulator +%= Map.nhash.0(n);
      };
      case(#Solana(_)){
        accumulator +%= 6454;
      };
      case (#Bitcoin(?n)){
        accumulator +%= 23424234;
        accumulator +%= Map.thash.0(n);
      };
      case(#Bitcoin(_)){
        accumulator +%= 23234;
      };
      case (#IC(?n)){
        accumulator +%= 584345234;
        accumulator +%= Map.thash.0(n);
      };
      case(#IC(_)){
        accumulator +%= 584345234;
      };
      case (#Other(n)){
        accumulator +%= 29384756;
        accumulator +%= ICRC16.hashShared(#Map(n));
      };
    };
    accumulator
  };

  public let networkHash = (NetworkHash32, NetworkEq):Map.HashUtils<Service.Network>;
  
  /* public func fusionRPCEq(f1: FusionRPCService, f2: FusionRPCService): Bool {
    f1 == f2;
  }; */

  /* public func rpcApiHash32(n: EVM_RPC.RpcApi): Nat32 {
    var accumulator = 0 : Nat32;
    accumulator +%= Map.thash.0(n.url);
    accumulator +%= switch(n.headers){
      case(null){
        394090492;
      };
      case(?h){
        ignore Array.map<EVM_RPC.HttpHeader, Nat32>(h, func(h: EVM_RPC.HttpHeader): Nat32{
          accumulator +%= Map.thash.0(h.name);
          accumulator +%= Map.thash.0(h.value);
          accumulator;
        });
        accumulator;
      };
    };
    accumulator;
  }; */
  
  /* public func ethRPCServiceHash32(f: {
    canisterId: Principal;
    rpc: EVM_RPC.RpcService
    
  }): Nat32 {
   var accumulator = 0 : Nat32;
    switch (f.rpc) {
      case(#EthSepolia(n)){
        accumulator +%= 943400239;
        accumulator +%= switch(n){
          case(#Alchemy){
            494834;
          };
          case(#BlockPi){
            23058673;
          };
          case(#Cloudflare){
            548678120;
          };
          case(#PublicNode){
            1038475783;
          };
          case(#Ankr){
            2498743;
          };
        };

      };
      case(#BaseMainnet(n)){
        accumulator +%= 2128271172;
        accumulator +%= switch(n){
          case(#Alchemy){
            4945985;
          };
          case(#BlockPi){
            88289374;
          };
          case(#PublicNode){
            2385856894;
          };
          case(#Ankr){
            6825483;
          };
        };
      };
      case(#Custom(n)){
        //public type RpcApi = { url : Text; headers : ?[HttpHeader] };
        //public type HttpHeader = { value : Text; name : Text };
        accumulator +%= 304934;
        accumulator +%= rpcApiHash32(n);
      };
      case(#OptimismMainnet(n)){
        accumulator +%= 130984754;
        accumulator +%= switch(n){
          case(#Alchemy){
            9835398;
          };
          case(#BlockPi){
            67867098;
          };
          case(#PublicNode){
            2342395671;
          };
          case(#Ankr){
            193748964;
          };
        };
      };
      case(#ArbitrumOne(n)){
        accumulator +%= 7264758;
        accumulator +%= switch(n){
          case(#Alchemy){
            3847363;
          };
          case(#BlockPi){
            596689383;
          };
          case(#PublicNode){
            987893655;
          };
          case(#Ankr){
            2098465;
          };
        };
      };
      case(#EthMainnet(n)){
        accumulator +%= 3480824;
        accumulator +%= switch(n){
          case(#Alchemy){
            2342087534;
          };
          case(#BlockPi){
            217283945;
          };
          case(#Cloudflare){
            9864442;
          };
          case(#PublicNode){
            64758647;
          };
          case(#Ankr){
            32267890;
          };
        };
      };

      case(#Chain(n)){
        accumulator +%= 943268789;
        accumulator +%= Map.n64hash.0(n);
      };
      case(#Provider(n)){
        accumulator +%= 9983368;
        accumulator +%= Map.n64hash.0(n);
      };
    };
    if(accumulator == 0){
      accumulator += 1; //0xfffffffff is reserved
    };
    accumulator +%= Map.phash.0(f.canisterId);
    accumulator;
  }; */

 /*  public func fusionRPCHash32(f: FusionRPCService): Nat32 {
    var accumulator = 0 : Nat32;
    switch (f) {
      case (#Ethereum(n)){
        accumulator +%= 234234;
        accumulator +%= ethRPCServiceHash32(n);
      };
      case (#Solana(n)){
        accumulator +%= 467434;
        accumulator +%= switch(n.rpc){
          case(#Generic(n)){
            var x : Nat32 = 467434; 
            x +%= rpcApiHash32(n);
            x;
          };
        };
        accumulator +%= Map.phash.0(n.canisterId);
      };

      case (#Bitcoin(n)){
        accumulator +%= 502384;
        accumulator +%= switch(n.rpc){
          case(#Generic(n)){
            var x : Nat32 = 9863649; 
            x +%= rpcApiHash32(n);
            x;
          };
          
        };
        accumulator +%= Map.phash.0(n.canisterId);
      };
      case (#IC(n)){
        accumulator +%= 754334234;
        accumulator +%= switch(n.rpc){
          case(#Generic(n)){
            var x : Nat32 = 754334234; 
            x +%= rpcApiHash32(n);
            x;
          };
        };
        accumulator +%= Map.phash.0(n.canisterId);
      };
     
      case (#Other(n)){
        accumulator +%= 923567;
        accumulator +%= ICRC16.hashShared(#Map(n));
      };
    };
    if(accumulator == 0){
      accumulator += 1; //0xfffffffff is reserved
    };
    accumulator
  };

  public let fusionRPCHash = (fusionRPCHash32, fusionRPCEq):Map.HashUtils<FusionRPCService>; */

  /* public type HostingNetworkDetail = {
    network: Network;
    fusionRPC: FusionRPCService;    
  }; */

  public type RemoteOwnerMap = BTree.BTree<Nat, RemoteOwner>;
  public type OriginalMinterMap = BTree.BTree<Nat, Service.Account>;
  //public type NetworkMap = Map.Map<Nat, HostingNetworkDetail>;

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
    #Completed: Nat; //block of local transfer to address
    #Error: Service.CastError;
  };

  /// MARK: State
  /// `State`
  ///
  /// Represents the mutable state of the ICRC-99 token ledger, including all necessary variables for its operation.

  public type State = {
    var nativeChain : RemoteContractPointer;
    var orchestrator : Principal;
    var service : ?Principal;
    var remoteOwnerMap : RemoteOwnerMap;
    var originalMinterMap : OriginalMinterMap;
    //var networkMap : NetworkMap;
    var castStates : BTree.BTree<Nat, CastState>;
    var pendingCasts: Vector.Vector<Nat>;
    var nextCastId : Nat;
    icrc85 : {
      var nextCycleActionId : ?Nat;
      var lastActionReported : ?Nat;
      var activeActions : Nat;
    };
    cycleSettings : {
      var amountPerEthOwnerRequest : Nat;
      var amountPerSolanaOwnerRequest : Nat;
      var amountPerBitcoinOwnerRequest : Nat;
      var amountPerICOwnerRequest : Nat;
      var amountPerOtherOwnerRequest : Nat;
      var amountBasePerOwnerRequest : Nat;
      var cycleLedgerCanister: Principal;

      var amountPerETHCast: Nat;
    };
  };


  /// `Stats`
  ///
  /// Represents collected statistics about the ledger, such as the total number of accounts.
  public type Stats = {
    service: ?Principal;
    orchestrator: Principal;
    nativeChain: RemoteContractPointer;
    remoteOwnerMap: [(Nat, RemoteOwner)];
    originalMinterMap: [(Nat, Account)];
    nextCastId: Nat;
    cycleSettings: {
      amountPerEthOwnerRequest: Nat;
      amountPerSolanaOwnerRequest: Nat;
      amountPerBitcoinOwnerRequest: Nat;
      amountPerICOwnerRequest: Nat;
      amountPerOtherOwnerRequest: Nat;
      amountBasePerOwnerRequest: Nat;
      cycleLedgerCanister: Principal;
      amountPerETHCast: Nat;
    };
      
  };

   public type ICRC85Options = {
    kill_switch: ?Bool;
    handler: ?(([(Text, [(Text, ICRC16.CandyShared)])]) -> ());
    period: ?Nat;
    tree: ?[Text];
    asset: ?Text;
    platform: ?Text;
    collector: ?Principal;
  };

  public type AdvancedSettings = ?{
    icrc85 : ICRC85Options;
  };

  /// `Environment`
  ///
  /// A record that encapsulates various external dependencies and settings that the ledger relies on
  /// for fee calculations, timestamp retrieval, and inter-canister communication.
  /// can_transfer supports evaluating the transfer from both sync and async function.
  public type Environment = {
    icrc7 : ICRC7.ICRC7;
    addRecord: ?(<system>(ICRC16.ValueShared, ?ICRC16.ValueShared) -> Nat);
    advanced : AdvancedSettings;
  };

  
  /// `TxLog`
  ///
  /// A vector holding a log of transactions for the ledger.
  public type TxLog = Vector.Vector<ICRC16.ValueShared>;

  /// `MetaDatum`
  ///
  /// Represents a single metadata entry as a key-value pair.
  public type ICRC3MetaDatum = (Text, ICRC16.ValueShared);

  /// `MetaData`
  ///
  /// A collection of metadata entries in a `Value` variant format, encapsulating settings and properties related to the ledger.
  public type ICRC3MetaData = ICRC16.ValueShared;

  public type InitArgs = ?InitArgsList;

  public type InitArgsList = {
    nativeChain: RemoteContractPointer;
    service: ?Principal;
  };
};