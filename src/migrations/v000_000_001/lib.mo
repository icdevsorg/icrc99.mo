import D "mo:base/Debug";
import Principal "mo:base/Principal";
import Vec "mo:vector";
import Set "mo:map/Set";
import MigrationTypes "../types";

import v0_0_1 "types";

module {

  let Map = v0_0_1.Map;
  let Set = v0_0_1.Set;
  let BTree = v0_0_1.BTree;
  let Vector = v0_0_1.Vector;

  type Network = v0_0_1.Network;
  type RemoteContractPointer = v0_0_1.RemoteContractPointer;
  type RemoteOwner = v0_0_1.RemoteOwner;
  type CastState = v0_0_1.CastState;
  type Account = v0_0_1.Account;


  public func upgrade(prevmigration_state: MigrationTypes.State, args: MigrationTypes.Args, caller: Principal): MigrationTypes.State {

    D.print("in migration upgrade " # debug_show((prevmigration_state, args, caller)));

    let (nativeChain) = switch(args){
      case(null){
        //todo: log an error
        ({network = #IC(null); contract=Principal.toText(caller);} : RemoteContractPointer)
      };
      case(?val){
        (val.nativeChain);
      };
    };

    let (service) = switch(args){
      case(null) null;
      case(?val) val.service;
    };

  
    let state : MigrationTypes.Current.State = {
      var owner = caller;
      var service = service;
      var nativeChain = nativeChain;
      var orchestrator = caller;
      var remoteOwnerMap = BTree.init<Nat, RemoteOwner>(null); 
      var originalMinterMap = BTree.init<Nat, Account>(null);
      //var networkToRPCMap = Map.new<v0_0_1.Network, Set.Set<v0_0_1.FusionRPCService>>();
      var castStates = BTree.init<Nat, CastState>(null);
      var pendingCasts = Vector.new<Nat>();
      var nextCastId = 0;
      icrc85 = {
        var nextCycleActionId = null;
        var lastActionReported = null;
        var activeActions = 0;
      };
      settings = {
        tecdsaKeyName = "test_key_1";//key_1
      };
      cycleSettings = {
        var amountPerEthOwnerRequest = 2_500_000_000_000;
        var amountPerSolanaOwnerRequest = 2_500_000_000_000;
        var amountPerBitcoinOwnerRequest = 2_500_000_000_000;
        var amountPerICOwnerRequest = 2_500_000_000_000;
        var amountPerOtherOwnerRequest = 2_500_000_000_000; 
        var amountBasePerOwnerRequest = 1_000_000_000;
       
        var cycleLedgerCanister = Principal.fromText("um5iw-rqaaa-aaaaq-qaaba-cai");
        var amountPerETHCast = 1_000_000_000_000;
      }
    };

    return #v0_0_1(#data(state));
  };

};